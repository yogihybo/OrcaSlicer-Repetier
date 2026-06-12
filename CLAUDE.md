# Context
This change addresses a critical geometric requirement for multi-object printing on the build plate: **Raft Overlap Resolution**. Currently, when multiple distinct `PrintObject` instances are processed in isolation (especially when calculating base support layers), each object generates its own self-contained raft geometry and corresponding contact surfaces. If these rafts are close or overlap slightly, they will result in either visible seams/gaps between objects on the build plate surface, or redundant, disconnected geometric data that makes the support toolpath inefficient or visually inaccurate.

**The Goal:** Refactor the support generation pipeline to calculate a single, continuous, unified polygon set representing the combined *required* footprint of all printed objects (the "Mega-Raft Source"). This merged geometry must be used as the sole input for calculating the base interface layers and raft supports (`generate_raft_base`), ensuring that the final computed support structures are seamless and cohesive across object boundaries.

**Files Impacted:**
1.  `libslic3r/Support/Common.cpp`: Needs geometric function updates to accept a generalized polygon set instead of being tied to one `PrintObject`. (Specifically, updating or wrapping `generate_raft_base`).
2.  `libslic3r/Support/SupportMaterial.cpp`: Requires major structural changes in the primary support generation loop (`PrintObjectSupportMaterial::generate`) to gather and union all per-object footprints *before* calling raft calculation.

**Utilities to Reuse:**
*   `deps_src/libnest2d/include/libnest2d/utils/boost_alg.hpp`: The identified `nfp::merge` pattern for robust polygon set unions will be crucial in aggregating the initial object footprint polygons into one cohesive Mega-Raft Source Polygon set at the build plate level.
*   Core geometric primitives from `libslic3r/Support/Common.cpp`, such as `offset_ex`, `union_ex`, and `diff_ex`.

### Implementation Plan Details:

**1. Modify SupportMaterial::generate (Primary Orchestration Change)**
The goal is to shift the responsibility of *collecting* all footprint data from per-object iteration into a single collection step at the start of the function.

*   **Aggregation:** Before generating top/bottom contacts, we must iterate over all `PrintObject`s in the print job and collect their base footprints (`ExPolygons`). We will use a utility based on `nfp::merge` (or an equivalent operation using Boost Geometry's union functionality) to create one single, merged `MegaRaftSourcePolygon`.
*   **Pass-Through:** This singular polygon set must then be passed down the entire flow:
    *   Replace per-object calculations with a unified calculation that uses the `MegaRaftSourcePolygon` as the basis for defining support areas.

**2. Update Raft Generation (The Core Logic Change)**
Modify or introduce a wrapper around `generate_raft_base` in `libslic3r/Support/Common.cpp`. The function signature must change from accepting a single `PrintObject &object` to accepting the aggregated polygon footprint: `SupportsGeneratorLayersPtr generate_raft_base(const Polygons& collective_footprint, const SupportParameters& support_params, ...)`

*   **Raft Base Calculation:** Inside this updated function, all logic that currently uses `object.layers().front()->lslices` or `object.config().brim_type` must instead use the input `collective_footprint` to determine:
    a. The initial first layer polygon for the raft base (`first_layer`).
    b. The entire set of polygons used to calculate the subsequent interface/column supports.

**3. Refactoring Flow and Error Handling:**
*   Since this changes the function signatures and high-level control flow, it requires careful modification of multiple functions in `SupportMaterial.cpp` that rely on object context (e.g., line 1312: `for (size_t layer_id = 1; ...)`).
*   The initial steps must validate that the combined polygon set is non-empty and geometrically valid before proceeding with support calculation, preventing crashes caused by invalid union operations.

### Verification Plan
1.  **Unit Tests:** Add a targeted test case in the `tests/` directory that simulates two overlapping objects on the build plate (`AABB`) and asserts that the resulting base polygons from the unified raft generator are exactly equivalent to the expected merged geometry, rather than two separate geometries.
2.  **Functional Test (`verify`):** Use `verify` mode when running the application with a multi-object scenario that forces overlap (e.g., placing two circles close together). I will visually inspect the generated toolpaths/SVGs in the debug directory to confirm the support layers are continuous across object boundaries.

The plan requires significant refactoring, touching both high-level orchestration (`SupportMaterial.cpp`) and core geometry calculation (`Common.cpp`). This cannot be done with simple patch/edit commands.