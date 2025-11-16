#!/usr/bin/env bash
buildAndRunGo() {
  local program_name="$1"
  local src_dir="$2"
  local bin_dir="$3"
  local build_always_var="$4"
  shift 4  # Remove the first 4 arguments, leaving the program arguments
  
  echo "$program_name process started at: $(date)" >&2
  echo "buildAndRunGo: Source directory: $src_dir" >&2
  echo "buildAndRunGo: Binary directory: $bin_dir" >&2

  # Get current platform
  local exec_os
  exec_os=$(buildGoProgramGetOS) || {
    echo "Error getting OS" >&2
    return 1
  }
  local exec_arch
  exec_arch=$(buildGoProgramGetArch) || {
    echo "Error getting architecture" >&2
    return 1
  }
  local exec_binary="${bin_dir}/${program_name}-${exec_os}-${exec_arch}"
  [[ $exec_os == "windows" ]] && exec_binary="${exec_binary}.exe"

  # Smart build logic: only build if needed
  if command -v go &>/dev/null; then
    local should_build=true
    
    # Check if build always variable is set to 0 or not defined
    if [[ "${!build_always_var:-0}" == "0" ]]; then
      # Check if binary already exists
      if [[ -f "$exec_binary" ]]; then
        echo "Binary $exec_binary already exists and $build_always_var is 0, skipping build." >&2
        should_build=false
      else
        echo "Binary $exec_binary not found, building..." >&2
      fi
    else
      echo "$build_always_var is set to ${!build_always_var}, forcing build..." >&2
    fi

    # Build only if needed
    if [[ "$should_build" == "true" ]]; then
      echo "Go is installed. Starting build..." >&2
      local start_time=$(date +%s)
      buildGoProgram "$src_dir" "$bin_dir" "$program_name" || {
        echo "Build failed for some platforms. Attempting to use existing binary..." >&2
      }
      local end_time=$(date +%s)
      local duration=$((end_time - start_time))
      echo "Compilation process finished in $duration seconds." >&2
    fi
  else
    echo "Go is not installed. Attempting to use existing binary for $exec_os/$exec_arch..." >&2
  fi

  # Check if the binary exists
  if [[ ! -f $exec_binary ]]; then
    if [[ -f "$bin_dir/$program_name" ]]; then
      echo "Found generic binary $bin_dir/$program_name, using it instead" >&2
      exec_binary="$bin_dir/$program_name"
    else
      echo "Error: No binary found for $exec_os/$exec_arch ($exec_binary). Please install Go to build it or provide a precompiled binary." >&2
      return 1
    fi
  fi

  echo "--- Selected Executable Info ---" >&2
  stat "$exec_binary" >&2
  echo "--------------------------------" >&2

  # Ensure the binary is executable
  chmod +x "$exec_binary" || {
    echo "Error: Could not make $exec_binary executable." >&2
    return 1
  }

  # Execute the binary with all arguments
  echo "Executing $exec_binary with arguments: $*" >&2
  echo "-------------------------------- so the actual command is -----------------" >&2
  echo   "$exec_binary" "$@" >&2
  echo "--------------------------------" >&2

  "$exec_binary" "$@"
}
