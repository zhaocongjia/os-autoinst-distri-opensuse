
# Copyright 2019 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Installs and checks a service for migration scenarios
# Maintainer: Joachim Rauch <jrauch@suse.com>

use strict;
use warnings;
use base 'installbasetest';
use testapi;
use utils 'systemctl', 'zypper_call';
use service_check;
use version_utils qw(is_hyperv is_sle is_sles4sap);
use main_common 'is_desktop';

sub run {

    select_console 'root-console';

    script_run 'sudo -u gdm dbus-launch gsettings set org.gnome.desktop.session idle-delay 0';

    install_services($default_services)
      if is_sle
      && !is_desktop
      && !is_sles4sap
      && !is_hyperv
      && !get_var('MEDIA_UPGRADE')
      && !get_var('ZDUP')
      && !get_var('INSTALLONLY');

    if ($srv_check_results{'before_migration'} eq 'FAIL') {
        record_info("Summary", "failed", result => 'fail');
        die "Service check before migration failed!";
    }
}

sub test_flags {
    return {fatal => 0};
}

1;
