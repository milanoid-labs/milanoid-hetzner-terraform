# Off-site backup target for the family photo library on the Synology NAS
# (milanoid-labs/homelab-cluster#872). Synology Hyper Backup writes an encrypted,
# multi-version backup here over rsync/SSH (port 23), logged in as the `synology`
# subaccount, so the main account's credentials never go on the NAS. The subaccount's
# access_settings are what make port 23 reachable from home.

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

  # Main account: no remote access at all. Nothing logs in as it (Hyper Backup uses the
  # subaccount, which has its own access_settings), and it can see every subaccount's
  # directory, so it shouldn't accept password logins from the internet.
  access_settings = {
    ssh_enabled          = false
    reachable_externally = false
    samba_enabled        = false
    webdav_enabled       = false
    zfs_enabled          = false
  }

  # The copy the NAS can't touch. The synology subaccount can write, so whoever controls
  # the NAS (ransomware, a stolen DSM admin) can delete every Hyper Backup version in
  # synology/. Snapshots can only be made or deleted by the main account or the API, so
  # they survive that. Daily, keeping the last 10 (BX11's automatic-snapshot limit);
  # ZFS snapshots only hold what changed, so a mostly-append photo backup costs little
  # quota. Hour is UTC: after Hyper Backup's nightly run.
  snapshot_plan = {
    hour          = 6
    minute        = 0
    max_snapshots = 10
  }

  # Deletion guards. delete_protection stops deletion from the Console/API, but NOT from
  # tofu: the provider turns it off by itself before deleting. prevent_destroy only works
  # while this block exists. So tofu-apply also refuses any saved plan that destroys or
  # replaces an hcloud_storage_box (see .github/workflows/tofu-apply.yaml).
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
