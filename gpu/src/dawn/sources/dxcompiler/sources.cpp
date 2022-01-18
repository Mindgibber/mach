#define _In_range_(lb, ub)

#include "ir.cpp"
#include "ir_reader.cpp"
#include "bitcode.cpp"
#include "transforms.cpp"
#include "linker.cpp"
#include "analysis.cpp"
#include "option.cpp"
#include "target.cpp"
#include "asm_parser.cpp"
#include "profile_data.cpp"
#include "passes.cpp"
#include "pass_printers.cpp"
#include "dxc_support.cpp"
#include "hlsl.cpp"
#include "dxil.cpp"
#include "dxil_container.cpp"
#include "dxil_pix_passes.cpp"
// TODO(build-system): is this actually needed?
// if(WIN32) # HLSL Change
//   add_subdirectory(DxilDia) # HLSL Change
// endif(WIN32) # HLSL Change
#include "dxil_root_signature.cpp"
#include "dxc_binding_table.cpp"
#include "dxr_fallback.cpp"
#include "miniz.cpp"
