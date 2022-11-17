# SUSE's openQA tests
#
# Copyright 2017-2019 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Login as user test https://progress.opensuse.org/issues/13306
# Maintainer: Jozef Pupava <jpupava@suse.com>

use base "x11test";
use strict;
use warnings;
use testapi;
use x11utils 'handle_relogin';

sub run {
    select_console 'root-console';
    script_run('sed -i s/#Enable=true/Enable=true/g /etc/gdm/custom.conf');

    select_console 'x11';
    handle_relogin;

    select_console 'x11';
    handle_relogin;

    select_console 'x11';
    handle_relogin;

    select_console 'x11';
    handle_relogin;

    select_console 'x11';
    handle_relogin;
}

1;
