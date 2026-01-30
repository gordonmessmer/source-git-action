FROM fedora:latest

# Install mock, mock-scm, and other required packages
RUN dnf install -y \
    mock \
    mock-scm \
    git \
    rpm-build \
    && dnf clean all

# Create a mock user and add to mock group
RUN useradd -m -G mock mockbuild

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
