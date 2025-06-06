# SUSE's openQA tests
#
# Copyright 2017-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Upload Hyper-V assets
# Maintainer: Michal Nowak <mnowak@suse.com>

use base 'installbasetest';
use strict;
use warnings;
use testapi;
use version_utils;

use File::Basename 'fileparse_set_fstype';
use virt_autotest::hyperv_utils 'hyperv_cmd';

sub extract_assets {
    my ($args) = @_;

    my $name = $args->{name};
    my $format = $args->{format};

    my $hyperv_disk = get_var('HYPERV_DISK', 'D:');
    my $root = $hyperv_disk . get_var('HYPERV_ROOT', '');
    my $image_storage = "$root\\cache";
    my $svirt_img_name = $image_storage . '\\' . $args->{svirt_name} . ".$format";
    hyperv_cmd("dir $svirt_img_name");

    # On JeOS & MicroOS we use differential disk, so we need to merge before upload
    if (is_jeos || is_microos) {
        # Convert VHDX from differential disk to regular dynamic one
        hyperv_cmd("powershell -Command Convert-VHD -Path $svirt_img_name -DestinationPath ${svirt_img_name}.vhdx -VHDType Dynamic");
        hyperv_cmd("move /Y ${svirt_img_name}.vhdx $svirt_img_name");
    }
    hyperv_cmd("powershell -Command Optimize-VHD -Path $svirt_img_name -Mode Full");
    hyperv_cmd("powershell -Command Test-VHD -Path $svirt_img_name");
    hyperv_cmd("move /Y $svirt_img_name $image_storage\\$name");

    # Upload the image as a private asset; do the upload verification on your own, hence
    # the following assert_screen(). We need Windows filename path for a short amount of time.
    enter_cmd "cls";
    my $old_fstype = fileparse_set_fstype();
    fileparse_set_fstype('MSWin32');
    upload_asset("$image_storage\\$name", 1, 1);
    fileparse_set_fstype($old_fstype);
    assert_screen 'hyperv_image_uploaded', 1000;
}

sub run() {
    # connect to Hyper-V screen and upload asset from there
    my $svirt = select_console('svirt');

    # mark hard disks for upload if test finished
    my @toextract;
    for my $i (1 .. get_var('NUMDISKS')) {
        my $name = get_var("PUBLISH_HDD_$i") =~ s/qcow2/vhdx/r;
        next unless $name;
        push @toextract, {name => $name, format => 'vhdx', svirt_name => $svirt->name . "_$i"};
    }
    die 'Nothing to publish' unless @toextract;
    for my $asset (@toextract) {
        extract_assets($asset);
    }
}

1;
