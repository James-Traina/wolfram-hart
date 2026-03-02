#!/usr/bin/env bash
# Batch 7: Plotting & File Export (tests 061-070)
# Sourced by run-tests.sh. Defines test_* functions; do not execute directly.

test_061_basic_plot_export() {
    local f="/tmp/test_plot_061.png"
    rm -f "$f"
    run_eval "Export[\"$f\", Plot[Sin[x], {x, 0, 2 Pi}]]" 60
    assert_eq "$LAST_EXIT" "0" "plot export should succeed"
    assert_file_exists "$f" "plot PNG should be created"
}

test_062_plot_file_size() {
    local f="/tmp/test_plot_062.png"
    rm -f "$f"
    run_eval "Export[\"$f\", Plot[Sin[x], {x, 0, 2 Pi}, ImageSize -> 500]]" 60
    assert_file_size_gt "$f" 1000 "plot PNG should be > 1000 bytes"
}

test_063_3d_plot_export() {
    local f="/tmp/test_3d_063.png"
    rm -f "$f"
    run_eval "Export[\"$f\", Plot3D[Sin[x] Cos[y], {x, -Pi, Pi}, {y, -Pi, Pi}]]" 60
    assert_eq "$LAST_EXIT" "0" "3D plot should succeed"
    assert_file_exists "$f" "3D plot PNG should be created"
}

test_064_export_returns_path() {
    local f="/tmp/test_plot_064.png"
    rm -f "$f"
    run_eval "Export[\"$f\", Plot[x^2, {x, -2, 2}]]" 90
    assert_contains "$LAST_STDOUT" "$f" "Export should return the file path"
}

test_065_svg_export() {
    local f="/tmp/test_svg_065.svg"
    rm -f "$f"
    run_eval "Export[\"$f\", Plot[Cos[x], {x, 0, 2 Pi}]]" 60
    assert_file_exists "$f" "SVG file should be created"
}

test_066_imagesize_option() {
    local f="/tmp/test_plot_066.png"
    rm -f "$f"
    run_eval "Export[\"$f\", Plot[Sin[x], {x, 0, 2 Pi}, ImageSize -> 500]]" 60
    assert_eq "$LAST_EXIT" "0" "ImageSize option should be accepted"
    assert_file_exists "$f" "plot with ImageSize should create file"
}

test_067_listplot_export() {
    local f="/tmp/test_listplot_067.png"
    rm -f "$f"
    run_eval "Export[\"$f\", ListPlot[Table[{x, Sin[x]}, {x, 0, 2 Pi, 0.1}]]]" 90
    assert_file_exists "$f" "ListPlot should create file"
}

test_068_histogram_export() {
    local f="/tmp/test_hist_068.png"
    rm -f "$f"
    run_eval "Export[\"$f\", Histogram[RandomVariate[NormalDistribution[], 1000]]]" 60
    assert_file_exists "$f" "Histogram should create file"
}

test_069_plot_theme() {
    local f="/tmp/test_theme_069.png"
    rm -f "$f"
    run_eval "Export[\"$f\", Plot[Sin[x], {x, 0, 2 Pi}, PlotTheme -> \"Scientific\"]]" 60
    assert_eq "$LAST_EXIT" "0" "PlotTheme Scientific should work"
    assert_file_exists "$f" "themed plot should create file"
}

test_070_contour_plot() {
    local f="/tmp/test_contour_070.png"
    rm -f "$f"
    run_eval "Export[\"$f\", ContourPlot[x^2 + y^2, {x, -2, 2}, {y, -2, 2}]]" 60
    assert_file_exists "$f" "ContourPlot should create file"
}
