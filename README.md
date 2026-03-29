# buildAndRunGo.sh - Smart Go Program Builder and Runner

A Bash function that intelligently builds and runs Go programs with platform-aware binary selection and smart build caching.

## Parameters

### Required Parameters
1. **`program_name`** (string) - The name of the Go program/executable
2. **`src_dir`** (string) - Directory containing the Go source code
3. **`bin_dir`** (string) - Directory where binaries will be stored/retrieved
4. **`build_always_var`** (string) - Name of an environment variable that controls forced rebuilds
   - When set to any non-zero value: Always rebuild
   - When set to "0" or undefined: Use smart caching (only rebuild if binary doesn't exist)

### Optional Parameters
5. **Program arguments** (any number) - All remaining arguments are passed directly to the compiled Go program

## Usage Examples

### Basic Usage
```bash
# Build and run a Go program with smart caching
buildAndRunGo "myapp" "./src" "./bin" "FORCE_REBUILD" --config config.yaml

# With DEBUG enabled for detailed output
DEBUG=true buildAndRunGo "myapp" "./src" "./bin" "FORCE_REBUILD" --verbose
```

### Environment Variables

- **`DEBUG`** (optional): Set to "true" to enable detailed debug output
- **`build_always_var`** (variable name): The function checks an environment variable with this name:
  ```bash
  # Force rebuild every time
  export FORCE_REBUILD=1
  buildAndRunGo "myapp" "./src" "./bin" "FORCE_REBUILD"
  
  # Use smart caching (default behavior)
  export FORCE_REBUILD=0
  # or unset FORCE_REBUILD
  buildAndRunGo "myapp" "./src" "./bin" "FORCE_REBUILD"
  ```

### Platform-Specific Examples
```bash
# On Linux x86_64, creates: ./bin/myapp-linux-amd64
# On macOS ARM64, creates: ./bin/myapp-darwin-arm64
# On Windows x86_64, creates: ./bin/myapp-windows-amd64.exe
buildAndRunGo "myapp" "./src" "./bin" "BUILD_ALWAYS"
```

## Detailed Information

### Smart Build Logic

The function implements intelligent build caching:

1. **Go Installation Check**: First verifies Go is installed
2. **Build Condition Evaluation**:
   - If `build_always_var` is set to non-zero → Always rebuild
   - If `build_always_var` is "0" or undefined → Check if binary exists
   - Binary exists → Skip build
   - Binary missing → Build
3. **Platform Detection**: Uses `buildGoProgramGetOS` and `buildGoProgramGetArch` to determine target platform
4. **Binary Naming**: Creates platform-specific binaries: `{program}-{os}-{arch}` (with `.exe` on Windows)

### Fallback Behavior

1. **Go Not Installed**: Attempts to use existing precompiled binary
2. **Platform-Specific Missing**: Falls back to generic binary if available (`{bin_dir}/{program_name}`)
3. **No Binary Found**: Returns error with instructions

### Dependencies

The function relies on these existing utilities (assumed to be available):

- `buildGoProgramGetOS()` - Returns current operating system
- `buildGoProgramGetArch()` - Returns current architecture
- `buildGoProgram()` - Builds the Go program for multiple platforms

### Output Structure

```
{bin_dir}/
├── {program}-linux-amd64
├── {program}-darwin-arm64
├── {program}-windows-amd64.exe
└── {program} (generic fallback)
```

### Error Handling

- Returns exit code 1 on critical failures
- Provides clear error messages for missing dependencies
- Continues execution with fallback binaries when possible

### Performance Notes

- Build time is measured and reported when `DEBUG=true`
- Platform detection is cached within the function execution
- Binary existence checks are performed before building

### Security Considerations

- Ensures binaries are executable with `chmod +x`
- Uses platform-specific naming to prevent conflicts
- Validates binary existence before execution

## See Also

- `buildGoProgram` - For multi-platform Go builds
- `buildGoProgramGetOS` - OS detection utility
- `buildGoProgramGetArch` - Architecture detection utility
