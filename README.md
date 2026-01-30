# Mock SCM Build GitHub Action

A reusable GitHub Action that builds RPM packages using Mock with SCM (Source Control Management) integration. This action checks out your repository and builds it using Fedora's Mock build system.

## Features

- Uses a containerized Fedora environment with Mock and Mock-SCM pre-installed
- Supports building from any Git branch
- Configurable Fedora release version
- Automatic checkout and build from source control
- Returns build artifacts location
- Pre-built Docker image for faster workflow execution

## Docker Image

This action uses a pre-built Docker image hosted on GitHub Container Registry (ghcr.io) for faster execution. The image is automatically built and pushed when the Dockerfile or entrypoint script is updated.

The build-and-push workflow:
- Triggers on changes to `Dockerfile`, `entrypoint.sh`, or the build workflow itself
- Builds the image with Docker Buildx
- Pushes to `ghcr.io/gordonmessmar/source-git-action:latest`
- Uses GitHub Actions cache for faster subsequent builds

If you prefer to build from the Dockerfile on each run (slower but doesn't require the pre-built image), edit `action.yml` and change the image line to `image: 'Dockerfile'`.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `mock-root` | Mock build root configuration | Yes | - |
| `repo-name` | Repository/package name | No | Auto-detected from GitHub repository |
| `branch` | Git branch to build from | No | Auto-detected from current ref |
| `spec-file` | Path to spec file | No | `{repo-name}.spec` |
| `additional-options` | Additional options to pass to mock | No | `''` |

### Supported Mock Roots

The `mock-root` input accepts any valid Mock configuration. Common examples:

- **Fedora**: `fedora-39-x86_64`, `fedora-40-x86_64`, `fedora-41-x86_64`, `fedora-rawhide-x86_64`
- **AlmaLinux**: `almalinux-8-x86_64`, `almalinux-9-x86_64`, `almalinux-10-x86_64`
- **CentOS Stream**: `centos-stream-9-x86_64`, `centos-stream-10-x86_64`
- **RHEL**: `rhel-8-x86_64`, `rhel-9-x86_64` (if available)
- **Rocky Linux**: `rocky-8-x86_64`, `rocky-9-x86_64`

You can list available configurations on your system with `mock --list-chroots` or view them at `/etc/mock/`.

## Outputs

| Output | Description |
|--------|-------------|
| `result-dir` | Directory containing build results |

## Usage

### Basic Example

```yaml
name: Build RPM Package

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build with Mock
        uses: gordonmessmer/source-git-action@main
        with:
          mock-root: 'fedora-41-x86_64'
          # repo-name: 'mypackage'  # Optional: defaults to repository name
          # branch: 'main'          # Optional: defaults to current branch
```

### Advanced Example

```yaml
name: Build Multiple Distributions

on:
  push:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - mock-root: 'fedora-40-x86_64'
            name: 'fedora-40'
          - mock-root: 'fedora-41-x86_64'
            name: 'fedora-41'
          - mock-root: 'almalinux-9-x86_64'
            name: 'almalinux-9'
          - mock-root: 'centos-stream-10-x86_64'
            name: 'centos-stream-10'

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build with Mock for ${{ matrix.name }}
        id: mock-build
        uses: gordonmessmer/source-git-action@main
        with:
          mock-root: ${{ matrix.mock-root }}
          # repo-name and branch are auto-detected
          additional-options: '--verbose'

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: rpm-packages-${{ matrix.name }}
          path: ${{ steps.mock-build.outputs.result-dir }}/*.rpm
```

### Using with Custom Spec File

```yaml
- name: Build with custom spec for AlmaLinux
  uses: gordonmessmer/source-git-action@main
  with:
    mock-root: 'almalinux-10-x86_64'
    spec-file: 'packaging/myproject.spec'
    # repo-name and branch auto-detected from GitHub context
```

## How It Works

This action:

1. Uses a Fedora container with Mock and Mock-SCM pre-installed
2. Checks out your repository in the container
3. Runs the Mock build command with SCM integration:
   ```bash
   mock -r {mock-root} \
     --resultdir=/tmp/mock-localrepo-{unique-id} \
     --scm-enable \
     --scm-option method=git \
     --scm-option package={repo-name} \
     --scm-option branch={branch} \
     --scm-option spec={spec-file} \
     --scm-option write_tar=True \
     --scm-option 'git_get=git clone --branch {branch} .'
   ```
4. Outputs the location of build results

## Requirements

Your repository should contain:
- A valid RPM spec file (typically `{package-name}.spec`)
- Source code that matches the spec file expectations

## Mock Configuration

The action uses the default Fedora Mock configuration for the specified release. If you need custom Mock configurations, you can:

1. Add configuration files to your repository
2. Use the `additional-options` input to pass custom config options like `--configdir=./mock-configs`

## Troubleshooting

### Build fails with "spec file not found"

Ensure your spec file is in the repository root or provide the correct path using the `spec-file` input.

### Permission errors

The action runs Mock inside a container with appropriate permissions. If you encounter permission issues, check that your spec file doesn't require special file system permissions.

### Build artifacts not found

The build artifacts are stored in a temporary directory inside the container. Use the `result-dir` output to reference the correct location, or copy artifacts in a subsequent step.

## Development

To modify this action:

1. Clone the repository
2. Edit `Dockerfile`, `entrypoint.sh`, or `action.yml` as needed
3. Test locally using `act` or push to a test repository
4. Submit a pull request

## License

This action is released under the MIT License.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
