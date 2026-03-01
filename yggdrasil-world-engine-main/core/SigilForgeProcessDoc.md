# SigilForge Process Documentation

Overview
Process Name: SigilForge
Version: 1.0
Date: 2025-12-25
Description:
A procedural generation process for creating personalized geometric sigils from user-provided numeric seed data. The resulting sigil serves as an input image for further transformations in the SymDim Transformer pipeline, enabling higher-dimensional analysis, pattern exploration, and ties to mathematical/physics concepts.
Integration Note:
SigilForge is an optional input mode within the SymDim Transformer software, allowing users to generate sigils instead of uploading external images. The output sigil image feeds directly into the SymDim pipeline for X-D conversion and subsequent steps.
Input
Seed Data
Description: User-entered string of numbers (e.g., birthdate '20001225', physical constants '6.626e-34', or arbitrary sequences like '123456789'). Treated as a seed for deterministic generation.
Type: string
Validation: Must contain only digits, decimals, hyphens, or scientific notation. Non-numeric characters are ignored or hashed.
Examples:

19900101
3.1415926535
42-137-2025

Customization Parameters

num_points:
Default: 12
Range: [5, 30]
Description: Number of anchor points defining the sigil's geometry.

symmetry_order:
Default: 12
Range: [4, 24]
Description: Order of rotational symmetry (e.g., 12-fold for radial designs like the Black Sun).

complexity:
Default: "medium"
Options: ["low", "medium", "high"]
Description: Controls density of connections and curves: low (simple lines), medium (beziers), high (fractal-like branches).

style:
Default: "radial"
Options: ["radial", "linear", "grid", "chaotic"]
Description: Base motif: radial (circular emanations), linear (straight connections), grid (matrix-based), chaotic (randomized with seed constraints).

Workflow Steps

Step: Seed ProcessingActions:
Validate and sanitize input string (remove invalid characters).
Compute a hash of the seed (e.g., using std::hash<std::string> or CRC32 for a 64-bit integer).
Use the hash as a seed for a pseudo-random number generator (e.g., std::mt19937) to ensure reproducibility.
Output: Seeded RNG instance for consistent geometric parameter generation.

Step: Point GenerationActions:
Generate 'num_points' coordinates in a 2D plane using the seeded RNG.
For radial style: Use polar coordinates (angle = 360° / symmetry_order increments, radius = RNG-modulated between 0.1-1.0 normalized).
For other styles: Linear (along a line), grid (uniform matrix), chaotic (uniform random distribution).
Apply symmetry: Mirror or rotate points to enforce symmetry_order (e.g., duplicate and transform for rotational invariance).
Output: std::vector of 2D points (e.g., pairs of doubles for x,y).

Step: Connection and Shape BuildingActions:
Connect points based on style: Radial (from center to points), linear (sequential), grid (edges between neighbors), chaotic (Delaunay triangulation or RNG-selected edges).
Add curves if complexity > low: Use quadratic Bezier curves (control points from RNG).
For high complexity: Introduce branching (e.g., midpoint splits with RNG offsets).
Enforce mathematical accuracy: Ensure connections respect symmetry (e.g., transform edges across axes).
Output: List of lines, curves, or polygons defining the sigil geometry.

Step: Rendering to ImageActions:
Create a canvas (e.g., 512x512 cv::Mat in OpenCV, initialized to white).
Draw points as small circles (cv::circle).
Draw connections as lines (cv::line) or polylines for curves.
Apply anti-aliasing and thickness based on complexity.
Convert to grayscale/binary if needed for SymDim input.
Output: In-memory image (cv::Mat) ready for SymDim pipeline.

Step: Preview and ExportActions:
Display preview in UI (e.g., MFC window or OpenCV imshow for testing).
Optionally save as PNG (cv::imwrite).
Feed directly to SymDim Transformer's Image Acquisition step.

Rules for Mathematical Accuracy

Reproducibility: Same seed always yields identical sigil (deterministic hashing and RNG).
Symmetry Enforcement: Apply transformations (rotations, mirrors) to maintain specified order, using matrix operations (e.g., Eigen for rotations).
Scaling: Normalize coordinates to unit circle/square for consistent rendering regardless of num_points.
Edge Cases: Handle low points (e.g., min 5) by defaulting to pentagonal symmetry; warn on invalid seeds.

Applications

Mathematics: Generate test geometries for symmetry group analysis or fractal seeding.
Physics: Seed simulations with personalized patterns for higher-D projections or entropy calculations.
Gaming: Procedural asset creation (e.g., unique runes or emblems based on player data).

Future Extensions

Support text seeds (convert via ASCII sum or hashing).
Integrate ML for style enhancement (e.g., auto-refine curves).
Export to vector formats (SVG) for scalable use.
