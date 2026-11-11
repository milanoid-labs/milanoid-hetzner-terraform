# Off-site backup target for the family photo library on the Synology NAS
# (milanoid-labs/homelab-cluster#872). Synology Hyper Backup writes an encrypted,
# multi-version backup here over rsync/SSH (port 23), logged in as the `synology`
# subaccount, so the main account's credentials never go on the NAS.

# Hetzner's Storage Box password policy (applies to boxes and subaccounts): 12-128 chars,
# at least one upper case letter, lower case letter, number and special character, from
# a fixed set. override_special is a subset of that set, minus characters that are awkward
# to paste into shells and web forms (/ & ^ ° §).
resource "random_password" "storage_box" {
  length           = 32
  special          = true
  override_special = "!#$%()*+,-.:;=?@_{}~"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "synology" {
  length           = 32
  special          = true
  override_special = "!#$%()*+,-.:;=?@_{}~"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "hcloud_storage_box" "nas_backup" {
  name             = "nas-backup"
  storage_box_type = "bx11" # 1 TiB; the photo library is ~425 GB after dedup
  location         = "fsn1"
  password         = random_password.storage_box.result

  access_settings = {
    # Hyper Backup's "rsync-compatible server" destination uses SSH on port 23, from home.
    ssh_enabled          = true
    reachable_externally = true
    samba_enabled        = false
    webdav_enabled       = false
    zfs_enabled          = false
  }

  # No snapshot_plan: Hyper Backup already keeps versions, and Storage Box snapshots
  # count against the 1 TiB quota.

  # Two guards: delete_protection stops deletion from the Console/API, prevent_destroy
  # stops a plan that would destroy (or replace) the box. This box holds the NAS's only
  # off-site copy; removing it on purpose means editing both out first.
  delete_protection = true

  labels = {
    purpose    = "nas-backup"
    managed-by = "opentofu"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_storage_box_subaccount" "synology" {
  storage_box_id = hcloud_storage_box.nas_backup.id
  name           = "synology"
  description    = "Synology Hyper Backup (NAS2)"
  home_directory = "synology"
  password       = random_password.synology.result

  access_settings = {
    ssh_enabled          = true
    reachable_externally = true
    readonly             = false
    samba_enabled        = false
    webdav_enabled       = false
  }

  labels = {
    purpose    = "nas-backup"
    managed-by = "opentofu"
  }
}
