{ callPackage, fetchpatch }:

let
  common = callPackage ./common.nix { };
in
{
  mir = common {
    version = "2.19.2";
    hash = "sha256-E6+FjYJUIgejpat1Kyl0B1JL+mnQd4rXjSQAPTX31qc=";
  };

  mir_2_15 = common {
    version = "2.15.0";
    pinned = true;
    hash = "sha256-c1+gxzLEtNCjR/mx76O5QElQ8+AO4WsfcG7Wy1+nC6E=";
    patches = [
      # Fix gbm-kms tests
      # Remove when version > 2.15.0
      (fetchpatch {
        name = "0001-mir-Fix-the-signature-of-drmModeCrtcSetGamma.patch";
        url = "https://github.com/canonical/mir/commit/98250e9c32c5b9b940da2fb0a32d8139bbc68157.patch";
        hash = "sha256-tTtOHGNue5rsppOIQSfkOH5sVfFSn/KPGHmubNlRtLI=";
      })
      # Fix external_client tests
      # Remove when version > 2.15.0
      (fetchpatch {
        name = "0002-mir-Fix-cannot_start_X_Server_and_outdated_tests.patch";
        url = "https://github.com/canonical/mir/commit/0704026bd06372ea8286a46d8c939286dd8a8c68.patch";
        hash = "sha256-k+51piPQandbHdm+ioqpBrb+C7Aqi2kugchAehZ1aiU=";
      })

      # Fix ignored return value of std::lock_guard
      # Remove when version > 2.15.0
      # Was changed as part of the big platform API change, no individual upstream commit with this fix
      ./1001-mir-2_15-Fix-ignored-return-value-of-std-lock_guard.patch

      # Fix missing includes for methods from algorithm
      # Remove when version > 2.16.4
      # https://github.com/canonical/mir/pull/3191 backported to 2.15
      ./1002-mir-2_15-Add-missing-includes-for-algorithm.patch

      # Fix order of calloc arguments
      # Remove when version > 2.16.4
      # Partially done in https://github.com/canonical/mir/pull/3192, though one of the calloc was fixed earlier
      # when some code was moved into that file
      ./1003-mir-2_15-calloc-args-in-right-order.patch
    ];
  };
}
