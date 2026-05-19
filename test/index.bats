#!/usr/bin/env bats

mock_stdin() {
  printf '#!/bin/sh\n' > "$MOCK_DIR/$1"
  /bin/chmod +x "$MOCK_DIR/$1"
  cat >> "$MOCK_DIR/$1"
}

setup() {
  MOCK_DIR="$(mktemp -d)"
  INSTALL_DIR="$(mktemp -d)"

  # note that heredocs needs tabs for indent and not spaces
  mock_stdin uname <<-EOF
	case "\$1" in
	  -m) echo "\${MOCK_MACHINE:-x86_64}" ;;
	  *)  echo "\${MOCK_OS:-Linux}" ;;
	esac
	EOF

  # note that heredocs needs tabs for indent and not spaces
  mock_stdin curl <<-EOF
	printf "%s\n" "\${MOCK_CURL_OUTPUT:-binary-content}"
	exit \${MOCK_CURL_EXITCODE:-0}
	EOF

  # note that heredocs needs tabs for indent and not spaces
  mock_stdin chmod <<-EOF
	exit 0
	EOF

  # Restrict PATH to mocks + /bin so tests are isolated from the real curl/wget/uname
  export PATH="$MOCK_DIR:/bin"
  export K0S_VERSION="v1.30.0"
  export K0S_INSTALL_PATH="$INSTALL_DIR"
}

teardown() {
  rm -rf "$MOCK_DIR" "$INSTALL_DIR"
}

@test "installs k0s binary to the install path" {
  run "${BATS_TEST_DIRNAME}/../index.html"
  [ "$status" -eq 0 ]
  [ -f "$INSTALL_DIR/k0s" ]
}

