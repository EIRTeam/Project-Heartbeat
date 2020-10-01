cd ProjectHeartbeatDiscord
cargo build --release
cp "target/release/libproject_heartbeat_discord.so" "../../discord/bin"
cd ..
cd audio_utils
cargo build
cargo build --release --target x86_64-pc-windows-gnu
cp "target/debug/libgodot_audio_utils.so" "../../audio_utils/bin"
cp "target/x86_64-pc-windows-gnu/release/godot_audio_utils.dll" "../../audio_utils/bin"
