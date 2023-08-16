function model_compiled = createTestModel(varargin)

evalin('base', 'clear matrixConstant vectorConstant structScalar structMixed');

global model_name  model_compiled

model_name = 'simple';

%% creating a new model

% delete model if it already exists
warning('off','MATLAB:DELETE:FileNotFound');
delete(sprintf('%s.slx',model_name));

% create the new model
new_system(model_name);
save_system(model_name);

%% adding blocks

% -- root system

% math blocks
add_block('simulink/Math Operations/Gain', [model_name '/Gain1']);
add_block('simulink/Math Operations/Gain', [model_name '/Gain2']);

% input ports
helper_input_gen_WithInputs(model_name);

% output ports
add_block('simulink/Sinks/Out1',  [model_name '/Out1_ScalarDouble']);
set_param([model_name '/Out1_ScalarDouble'], 'IconDisplay',    'Signal name');
set_param([model_name '/Out1_ScalarDouble'], 'OutDataTypeStr', 'double');
    
add_block('simulink/Sinks/Out1',  [model_name '/Out2_ScalarUint32']);
set_param([model_name '/Out2_ScalarUint32'], 'IconDisplay',    'Signal name');
set_param([model_name '/Out2_ScalarUint32'], 'OutDataTypeStr', 'uint32');

%% set block properties

gain1Param = '2';
gain2Param = '0';


% math blocks
set_param([model_name '/Gain1'], 'Gain',           gain1Param);
set_param([model_name '/Gain1'], 'OutDataTypeStr', 'double');

set_param([model_name '/Gain2'], 'Gain',           gain2Param);
set_param([model_name '/Gain2'], 'OutDataTypeStr',   'uint32');
%set_param([model_name '/Gain2'], 'ParamDataTypeStr', 'uint32');

add_line(model_name, 'In1_ScalarDouble/1', 'Gain1/1');
add_line(model_name, 'Gain1/1',            'Out1_ScalarDouble/1');
add_line(model_name, 'In2_ScalarUint32/1', 'Gain2/1');
add_line(model_name, 'Gain2/1',            'Out2_ScalarUint32/1');

%% signal naming

% name the signals
name_output_signal([model_name '/In1_ScalarDouble'], 1, 'In1_ScalarDouble');
name_output_signal([model_name '/In2_ScalarUint32'], 1, 'In2_ScalarUint32');

name_input_signal([model_name '/Out1_ScalarDouble'], 1, 'Out1_ScalarDouble');
name_input_signal([model_name '/Out2_ScalarUint32'], 1, 'Out2_ScalarUint32');

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

delete(sprintf('%s.slx',model_name));
delete(sprintf('%s.slxc',model_name));
delete(sprintf('%s.slx.bak',model_name));

% 
warning('on','MATLAB:DELETE:FileNotFound');
warning('on', 'all');

end   % function

%Helper functions, just to keep main code flow tidy, block-structured and
%easier to focus on


function helper_input_gen_WithInputs(model_name)

  add_block('simulink/Sources/In1', [model_name '/In1_ScalarDouble']);
    set_param([model_name '/In1_ScalarDouble'], 'IconDisplay',    'Signal name');
    set_param([model_name '/In1_ScalarDouble'], 'OutDataTypeStr', 'double');
    
    add_block('simulink/Sources/In1', [model_name '/In2_ScalarUint32' ]);
    set_param([model_name '/In2_ScalarUint32'],  'IconDisplay',    'Signal name');
    set_param([model_name '/In2_ScalarUint32'],  'OutDataTypeStr', 'uint32');
end

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