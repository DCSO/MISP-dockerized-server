##################################################
# MISP Dependencies:
    python_cybox_TAG=v2.1.0.12
    python_stix_TAG=v1.1.1.4
    mixbox_TAG=v1.0.2
    cake_resque_TAG=4.1.2

# Build Arguments
BUILD_ARGS="
    --build-arg MISP_TAG="$VERSION" \
    --build-arg python_cybox_TAG="$python_cybox_TAG" \
    --build-arg python_stix_TAG="$python_stix_TAG" \
    --build-arg mixbox_TAG="$mixbox_TAG" \
    --build-arg cake_resque_TAG="$cake_resque_TAG" \
"
##################################################
