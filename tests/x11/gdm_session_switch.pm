# SUSE's openQA tests
#
# Copyright 2016-2019 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: gdm gnome-terminal nautilus
# Summary: Add a case for gdm session switch
#    openSUSE has shipped SLE-Classic since Leap 42.2, this case will test
#    gdm session switch among sle-classic, gnome-classic, icewm and gnome.
#    Also test rebooting from login screen.
# Maintainer: Chingkai Chu <chuchingkai@gmail.com>

use base "x11test";
use strict;
use warnings;
use testapi;
use utils;
use version_utils 'is_sle';
use x11utils 'handle_gnome_activities';

# Smoke test: launch some applications
sub application_test {
    x11_start_program('gnome-terminal');
    send_key "alt-f4";

    x11_start_program('nautilus');
    send_key "alt-f4";
}

sub run {
    my ($self) = @_;

    x11_start_program('xterm');
    become_root;
    assert_script_run q{sed -i -e '$aEnvironment=SYSTEMD_LOG_LEVEL=debug' /usr/lib/systemd/system/systemd-logind.service};
    assert_script_run "wget http://dist.suse.de/install/SLP/SLE-15-SP5-Module-Development-Tools-LATEST/x86_64/DVD1/x86_64/evtest-1.33-1.19.x86_64.rpm";
    assert_script_run "rpm -i evtest-1.33-1.19.x86_64.rpm";
    assert_script_run "wget " . autoinst_url . "/data/x11/gnome-shell-41.9-150400.3.10.1.x86_64.rpm";
    assert_script_run "rpm -i --force gnome-shell-41.9-150400.3.10.1.x86_64.rpm";
    assert_script_run "wget " . autoinst_url . "/data/x11/systemd-249.16-150400.8.32.3.x86_64.rpm";
    assert_script_run "rpm -i --force systemd-249.16-150400.8.32.3.x86_64.rpm";

    script_run('sed -i s/#Enable=true/Enable=true/g /etc/gdm/custom.conf');
    enter_cmd "reboot";
    $self->wait_boot(bootloader_time => 300);
    select_console('log-console', timeout => 180);
    enter_cmd "systemd-cat evtest /dev/input/event0 &";
    select_console('x11');

    $self->prepare_sle_classic;
    $self->application_test;

    # Log out and switch to icewm
    $self->switch_wm;
    assert_and_click "displaymanager-settings";
    assert_and_click "dm-icewm";
    send_key "ret";
    assert_screen "desktop-icewm";
    # Smoke test: launch some applications
    send_key "super-spc";
    wait_still_screen(2);
    enter_cmd "gnome-terminal";
    assert_screen "gnome-terminal";
    send_key "alt-f4";
    send_key "super-spc";
    wait_still_screen(2);
    enter_cmd "nautilus";
    assert_screen "test-nautilus-1";
    send_key "alt-f4";
    wait_still_screen;

    # Log out and switch back to GNOME(default)
    send_key "ctrl-alt-delete";
    assert_screen "icewm-session-dialog";
    send_key "alt-l";
    wait_still_screen(2);
    send_key "alt-o";
    $self->dm_login;
    assert_and_click "displaymanager-settings";
    assert_and_click "dm-gnome";
    send_key "ret";
    handle_gnome_activities;

    # Log out and switch to SLE classic
    $self->prepare_sle_classic;
    $self->application_test;
}

1;
