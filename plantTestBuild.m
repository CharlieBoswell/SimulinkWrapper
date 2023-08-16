function model_compiled = createTestModel(varargin)

evalin('base', 'clear matrixConstant vectorConstant structScalar structMixed');

global model_name  model_compiled

model_name = 'plant';

%% creating a new model

% delete model if it already exists
warning('off','MATLAB:DELETE:FileNotFound');
delete(sprintf('%s.slx',model_name));

% create the new model
new_system(model_name);
save_system(model_name);

add_block('simulink/User-Defined Functions/MATLAB Function', [model_name '/model']);
blockHandle = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', [model_name '/model']);
blockHandle.Script = fileread('plantTest.m');

% input ports

add_block('simulink/Sources/In1', [model_name '/In1']);
set_param([model_name '/In1'], 'IconDisplay',    'Signal name');
set_param([model_name '/In1'], 'OutDataTypeStr', 'double');

add_block('simulink/Sources/In1', [model_name '/In2']);
set_param([model_name '/In2'], 'IconDisplay',    'Signal name');
set_param([model_name '/In2'], 'OutDataTypeStr', 'double');

% output ports
add_block('simulink/Sinks/Out1',  [model_name '/Out1']);
set_param([model_name '/Out1'], 'IconDisplay',    'Signal name');
set_param([model_name '/Out1'], 'OutDataTypeStr', 'double');
    
add_line(model_name, 'In1/1', 'model/1');
add_line(model_name, 'In2/1','model/2');
add_line(model_name, 'model/1','Out1/1');

%% signal naming

% name the signal
name_output_signal([model_name '/In1'], 1, 'In1');
name_input_signal([model_name '/Out1'], 1, 'Out1');
name_input_signal([model_name '/Out1'], 1, 'Out2');

%% code generation
% name of each option is available by right-clicking on the option name
% in Model Settings dialog and then on "What's This?"

% Solver
set_param(model_name, 'SolverType', 'Fixed-step');

% Code Generation
set_param(model_name, 'SystemTargetFile', 'ert_shrlib.tlc');
set_param(model_name, 'RTWVerbose', 0);

% Optimization
set_param(model_name, 'DefaultParameterBehavior', 'Inlined');
set_param(model_name, 'OptimizationCustomize', 1);
set_param(model_name, 'GlobalVariableUsage', 'None');

% Report
set_param(model_name, 'GenerateReport', 0);

% Comments
set_param(model_name, 'GenerateComments', 0);

% Custom code (MODEL is a coder keyword for the model name)
    set_param(model_name, 'CustomSourceCode', ...
        [ ...
        '#define CONCAT(str1, str2, str3) CONCAT_(str1, str2, str3)'            newline, ...
        '#define CONCAT_(str1, str2, str3) str1 ## str2 ## str3'                newline, ...
        '#define GET_MMI_FUNC    CONCAT(MODEL     , _GetCAPImmi ,   )'          newline, ...
        '#define RT_MODEL_STRUCT CONCAT(RT_MODEL_ , MODEL       , _T)'          newline, ...
                                                                                newline, ...
        'void* GET_MMI_FUNC(void* voidPtrToRealTimeStructure)'                  newline, ...
        '{'                                                                     newline, ...
        '   rtwCAPI_ModelMappingInfo* mmiPtr = &(rtmGetDataMapInfo( ( RT_MODEL_STRUCT * )(voidPtrToRealTimeStructure) ).mmi);' newline, ...
        '   return (void*) mmiPtr;'                                             newline, ...
        '}' ...
        ] ...
    );

% Interface
set_param(model_name, 'SupportComplex', 0);
set_param(model_name, 'SupportAbsoluteTime', 0);
set_param(model_name, 'SuppressErrorStatus', 1);

set_param(model_name, 'CodeInterfacePackaging', 'Reusable function');

set_param(model_name, 'RootIOFormat', 'Part of model data structure');

set_param(model_name, 'RTWCAPIParams', 1);
set_param(model_name, 'RTWCAPIRootIO', 1);

set_param(model_name, 'GenerateAllocFcn', 1);

set_param(model_name, 'IncludeMdlTerminateFcn', 0);
set_param(model_name, 'CombineSignalStateStructs', 1);

% Templates
set_param(model_name, 'GenerateSampleERTMain', 0);

%% model build

try
    rtwbuild(model_name)
    model_compiled = true;
catch
    model_compiled = false;
end

    
%% save and close
save_system(model_name);
close_system(model_name);

% clean build directory

rmdir('slprj', 's');
rmdir([model_name '_ert_shrlib_rtw'], 's');

%delete(sprintf('%s.slx',model_name));
delete(sprintf('%s.slxc',model_name));
delete(sprintf('%s.slx.bak',model_name));

% 
warning('on','MATLAB:DELETE:FileNotFound');
warning('on', 'all');

end   % function

function name_input_signal(address, signal_index, signal_name)
    
    p = get_param(address, 'PortHandles');
    l = get_param(p.Inport(signal_index),'Line');
    set_param(l,'Name', signal_name);
    
end

function name_output_signal(address, signal_index, signal_name)
    
    p = get_param(address, 'PortHandles');
    l = get_param(p.Outport(signal_index),'Line');
    set_param(l,'Name', signal_name);
    
end
