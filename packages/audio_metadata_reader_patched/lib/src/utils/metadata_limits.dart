/// Maximum aggregate metadata bytes parsed from one audio file.
const maxMetadataBytes = 32 * 1024 * 1024;

/// Maximum bytes materialized for one metadata frame, box, item, or block.
const maxMetadataFrameBytes = 16 * 1024 * 1024;

/// Maximum decoded bytes retained for one embedded artwork image.
const maxEmbeddedArtworkBytes = 8 * 1024 * 1024;
