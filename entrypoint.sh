#!/bin/bash

# Input parameters from GitHub Action
MOCK_ROOT="${INPUT_MOCK_ROOT}"
REPO_NAME="${INPUT_REPO_NAME}"
BRANCH="${INPUT_BRANCH}"
SPEC_FILE="${INPUT_SPEC_FILE}"
ADDITIONAL_OPTIONS="${INPUT_ADDITIONAL_OPTIONS}"
EXTRACT_ARTIFACTS="${INPUT_EXTRACT_ARTIFACTS:-true}"

# Auto-detect repository name if not provided
if [ -z "$REPO_NAME" ]; then
    if [ -n "$GITHUB_REPOSITORY" ]; then
        # Extract repo name from owner/repo format
        REPO_NAME="${GITHUB_REPOSITORY##*/}"
        echo "Auto-detected repository name: $REPO_NAME"
    else
        echo "Error: repo-name could not be determined automatically"
        exit 1
    fi
fi

# Auto-detect branch if not provided
if [ -z "$BRANCH" ]; then
    if [ -n "$GITHUB_REF_NAME" ]; then
        BRANCH="${GITHUB_REF_NAME}"
        echo "Auto-detected branch: $BRANCH"
    else
        echo "Error: branch could not be determined automatically"
        exit 1
    fi
fi

# Validate required inputs
if [ -z "$MOCK_ROOT" ]; then
    echo "Error: mock-root is required"
    exit 1
fi

# Use repo name as spec file if not provided
if [ -z "$SPEC_FILE" ]; then
    SPEC_FILE="${REPO_NAME}.spec"
fi

echo "=========================================="
echo "Mock Build Configuration"
echo "=========================================="
echo "Mock Root: $MOCK_ROOT"
echo "Repository: $REPO_NAME"
echo "Branch: $BRANCH"
echo "Spec File: $SPEC_FILE"
echo "Result Directory: $RESULT_DIR"
echo "Working Directory: $(pwd)"
echo "=========================================="

# Build the mock command
MOCK_CMD="mock -r ${MOCK_ROOT} \
    --resultdir=${RESULT_DIR} \
    --scm-enable \
    --scm-option method=git \
    --scm-option package=${REPO_NAME} \
    --scm-option branch=${BRANCH} \
    --scm-option spec=${SPEC_FILE} \
    --scm-option write_tar=True \
    --scm-option 'git_get=git clone --branch ${BRANCH} $(pwd)'"

# Add any additional options
if [ -n "$ADDITIONAL_OPTIONS" ]; then
    MOCK_CMD="$MOCK_CMD $ADDITIONAL_OPTIONS"
fi

echo "Executing mock command:"
echo "$MOCK_CMD"
echo "=========================================="

# Execute mock command
eval "$MOCK_CMD"

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "=========================================="
    echo "Mock build completed successfully!"
    echo "Results are in: $RESULT_DIR"
    echo "=========================================="

    # List the results
    if [ -d "$RESULT_DIR" ]; then
        echo "Build artifacts:"
        ls -lh "$RESULT_DIR"
    fi
else
    echo "=========================================="
    echo "Mock build failed!"
    echo "=========================================="
    cat ${RESULT_DIR}/build.log
    exit 1
fi

echo "result-dir=$RESULT_DIR" >> "$RESULT_DIR/github_output"
