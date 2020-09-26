cd ProjectHeartbeatDiscord
cargo build --release
cp "target/release/libproject_heartbeat_discord.so" "../../discord/bin"
cd ..
cd godot_ebur128
cargo build --release
cargo build --release --target x86_64-pc-windows-gnu
cp "target/release/libgodot_ebur128.so" "../../ebur128/bin"
cp "target/x86_64-pc-windows-gnu/release/godot_ebur128.dll" "../../ebur128/bin"
