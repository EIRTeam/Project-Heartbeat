cd ProjectHeartbeatDiscord
cargo build --release
cp "target/release/libproject_heartbeat_discord.so" "../../discord/bin"
cd ..
cd ph_native_utils
cargo build
cargo build --release --target x86_64-pc-windows-gnu
cp "target/debug/libph_native_utils.so" "../../ph_native_utils/bin"
cp "target/x86_64-pc-windows-gnu/release/ph_native_utils.dll" "../../ph_native_utils/bin"
