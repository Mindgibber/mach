// TODO(build-system): is this needed?
//add_hlsl_hctgen(DxilPIXPasses OUTPUT DxilPIXPasses.inc BUILD_DIR)

#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilAddPixelHitInstrumentation.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilAnnotateWithVirtualRegister.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilDbgValueToDbgDeclare.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilDebugInstrumentation.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilForceEarlyZ.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilOutputColorBecomesConstant.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilPIXMeshShaderOutputInstrumentation.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilRemoveDiscards.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilReduceMSAAToSingleSample.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilShaderAccessTracking.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilPIXPasses.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilPIXVirtualRegisters.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/PixPassHelpers.cpp"
#include "DirectXShaderCompiler/lib/DxilPIXPasses/DxilPIXAddTidToAmplificationShaderPayload.cpp"
