from datetime import datetime, timezone
import os

from securesystemslib.interface import (
    generate_and_write_ecdsa_keypair,
    import_ecdsa_privatekey_from_file,
)
from tuf.api.metadata import Root, Snapshot, Targets, Timestamp

# Create directories
repository_dir = os.path.abspath("repository/staged")
keystore_dir = os.path.abspath("keystore")
metadata_dir = os.path.join(repository_dir, "metadata")
targets_dir = os.path.join(repository_dir, "targets")

# 1. Create keys and a root metadata file
root_path = os.path.join(keystore_dir, "root")
targets_path = os.path.join(keystore_dir, "targets")
snapshot_path = os.path.join(keystore_dir, "snapshot")
timestamp_path = os.path.join(keystore_dir, "timestamp")

root_key = generate_and_write_ecdsa_keypair(root_path, password="password")
targets_key = generate_and_write_ecdsa_keypair(targets_path, password="password")
snapshot_key = generate_and_write_ecdsa_keypair(snapshot_path, password="password")
timestamp_key = generate_and_write_ecdsa_keypair(timestamp_path, password="password")

root = Root(
    expires=datetime.now(timezone.utc).replace(microsecond=0) + (datetime(2030, 1, 1, 0, 0) - datetime.now()),
)
root.add_key(root_key, "root")
root.add_key(targets_key, "targets")
root.add_key(snapshot_key, "snapshot")
root.add_key(timestamp_key, "timestamp")

root.add_role("root", [root_key.keyid], 1)
root.add_role("targets", [targets_key.keyid], 1)
root.add_role("snapshot", [snapshot_key.keyid], 1)
root.add_role("timestamp", [timestamp_key.keyid], 1)

root_priv_key = import_ecdsa_privatekey_from_file(root_path, password="password")
root.sign(root_priv_key)
root.to_file(os.path.join(metadata_dir, "root.json"))

# 2. Create and sign other metadata
targets = Targets()
targets.add_target("myfile.txt", os.path.join(targets_dir, "myfile.txt"))
targets_priv_key = import_ecdsa_privatekey_from_file(targets_path, password="password")
targets.sign(targets_priv_key)
targets.to_file(os.path.join(metadata_dir, "targets.json"))

snapshot = Snapshot()
snapshot.add_meta("targets.json", targets.version)
snapshot_priv_key = import_ecdsa_privatekey_from_file(snapshot_path, password="password")
snapshot.sign(snapshot_priv_key)
snapshot.to_file(os.path.join(metadata_dir, "snapshot.json"))

timestamp = Timestamp()
timestamp.add_meta("snapshot.json", snapshot.version)
timestamp_priv_key = import_ecdsa_privatekey_from_file(timestamp_path, password="password")
timestamp.sign(timestamp_priv_key)
timestamp.to_file(os.path.join(metadata_dir, "timestamp.json"))

print("TUF repository created and signed.")
