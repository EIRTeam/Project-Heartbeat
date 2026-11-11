#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -z "${GODOT_BIN:-}" ]]; then
	candidates=(
		"${project_root}/../../ph-monorepo/engine/bin/godot.linuxbsd.editor.dev.x86_64"
		"${project_root}/../../ph-monorepo/buildeps/retail_bin/godot.linuxbsd.editor.x86_64"
	)
	for candidate in "${candidates[@]}"; do
		if [[ -x "${candidate}" ]]; then
			GODOT_BIN="${candidate}"
			break
		fi
	done
fi

if [[ -z "${GODOT_BIN:-}" || ! -x "${GODOT_BIN}" ]]; then
	echo "Could not find Godot. Set GODOT_BIN to the custom Godot executable." >&2
	exit 2
fi

exec "${GODOT_BIN}" \
	--headless \
	--path "${project_root}" \
	-s res://tests/test_runner.gd \
	-- --gdscript-tests "$@"
