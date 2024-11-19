MODULE Module1
    PERS wobjdata VisionArea:=[FALSE,TRUE,"",[[1869.68,709.512,484.819],[0.00343493,-0.695508,0.718077,-0.0249533]],[[0,0,0],[1,0,0,0]]];
    PERS wobjdata TurnJig:=[FALSE,TRUE,"",[[1869.68,709.512,484.819],[0.00343493,-0.695508,0.718077,-0.0249533]],[[0,0,0],[1,0,0,0]]];
    PERS wobjdata Buffer:=[FALSE,TRUE,"",[[256.779,-1069.69,610.067],[7.98967E-06,0.00534508,0.00268913,-0.999982]],[[0,0,0],[1,0,0,0]]];
    PERS wobjdata AGV_WOBJ:=[FALSE,TRUE,"",[[495.62,-931.089,522.962],[0.000678894,0.999995,-0.00285155,0.00102544]],[[0,0,0],[1,0,0,0]]];
    
    PERS tooldata Gripper:=[TRUE,[[0.529137,-2.11294,334.488],[0.900553,-0.111546,-0.379512,-0.180367]],[0.15,[1,1,1],[1,0,0,0],0,0,0]];
    PERS tooldata Pointer:=[TRUE,[[4.66274,1.67393,287.716],[1,0,0,0]],[0.1,[0,0,0],[1,0,0,0],0,0,0]];
    
    
    CONST robtarget Home_conveyor:=[[782.35,207.32,825.10],[0.364241,0.180612,0.904479,0.12894],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Home_agv:=[[466.97,-955.76,887.04],[0.0409164,-0.813528,0.580084,-0.00029237],[-1,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Default_Approach:=[[50,1608.383745154,849.965202049],[0.035526424,0.195727464,0.979999504,0.005441088],[0,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget TurnJigBottlePos:=[[50,1608.383745154,849.965202049],[0.035526424,0.195727464,0.979999504,0.005441088],[0,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    VAR robtarget bottleTarget:=[[457.95,609.33,51.57],[0.0345192,-0.697982,0.0105894,-0.715205],[0,1,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_Front_Left:=[[275.214282752,308.712923345,276.251377956],[0.668111629,-0.677808368,-0.209543029,0.2242641],[0,-1,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_Front_Right:=[[208.39575164,312.798963554,277.646500924],[0.663926289,-0.66245786,0.253933306,-0.236366967],[0,-2,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ContainerFrontPos:=[[121.30,108.45,193.59],[0.0243518,-0.73804,-0.671078,0.0660219],[-1,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget AGV_Container:=[[211.68,170.73,-204.84],[0.646012,0.046469,0.0566831,0.7598],[-1,-1,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    VAR bool Container{3,6}:=   [[FALSE,FALSE,FALSE,FALSE,FALSE,FALSE],
                                [FALSE,FALSE,FALSE,FALSE,FALSE,FALSE],
                                [FALSE,FALSE,FALSE,FALSE,FALSE,FALSE]];
    VAR num XPOS;
    VAR num YPOS;
    VAR num ZOrient;
    VAR intnum i:=1;
    VAR num offset;
    VAR bool full:=False;
    
    
    VAR string command;
    VAR intnum run_mode;
    VAR bool auto_mode;
    VAR intnum next_operation;
    VAR intnum bottle_type; !1=red, 2=blue, 3=yellow
    VAR num x_coordinate;
    VAR num y_coordinate;
    VAR num rotation;
    VAR num container_offset:=300;
    VAR intnum container_full{3}:=[0,0,0];
    VAR string taske;
    VAR string handshake;
    VAR num euler_angle_x;
    VAR num euler_angle_y;
    VAR num euler_angle_z;
    VAR bool turn_needed:=false;
    
    LOCAL CONST robtarget r10:=[[1239.80,425.27,532.05],[0.598452,-0.407849,0.514928,-0.458654],[0,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    LOCAL CONST robtarget r20:=[[1239.81,425.27,421.01],[0.598451,-0.407849,0.514929,-0.458654],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    LOCAL CONST robtarget r30:=[[1235.58,420.41,517.18],[0.618573,0.218864,0.741644,0.139391],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    VAR num reg6:=0;
    VAR num reg7:=0;
    VAR num reg8:=0;
    VAR num reg9:=0;
PROC main()
    SetDO doValve1,0;
    TPReadFK run_mode,"How should the Program Run?","Auto Mode", "Manual Mode", stEmpty,stEmpty,stEmpty;
        IF run_mode=1 THEN
            auto_mode:=TRUE;
        ELSE
            auto_mode:=FALSE;
        ENDIF
        
        IF auto_mode THEN
           RobotAsClientConnect;
            TPWrite "Connected to Python server."; 
        ENDIF
MoveJ Home_conveyor, v1000, z100, tool0\WObj:=wobj0;
    WHILE TRUE DO
        ! Attempt to receive a message from the Python server
        IF auto_mode THEN
                ! Receive command from the Python server
                 command := RobotClientReciveMessage();
                SplitMessage;
                startProces;
                WaitTime 3;
            ELSE
                ! Get new Operation by Operator
                TPReadFK next_operation,"Next Operation:","Pick Bottle", "Place Bottle", "Switch Container",stEmpty,stEmpty;
                IF next_operation=1 THEN
                    taske:="pickbottle";
                ELSEIF next_operation=2 THEN
                    taske:="placebottle";
                ELSEIF next_operation=3 THEN
                    taske:="containerswitch";
                ENDIF
            ENDIF
       
        IF taske <> "" THEN
            TPWrite taske;
            !WaitTime 10;
            ! Execute the command based on the message
            IF taske = "pickbottle" THEN
                TPWrite "Executing PickBottle...";
                PickBottle;
                WaitTime 1;
            ELSEIF taske = "placebottle" THEN
                TPWrite "Executing PlaceBottle...";
                PlaceBottle;
                WaitTime 1;
            ELSEIF taske = "containerswitch" THEN
                TPWrite "Executing ContainerSwitch...";
                IF not auto_mode THEN
                    TPReadFK bottle_type,"What colour is the bottle?","Red","Blue","Yellow",stEmpty,stEmpty;
                ENDIF
                ContainerSwitcheroo(bottle_type);
                WaitTime 1;
            ELSE
                TPWrite "Unknown command from Python: " + taske;
                WaitTime 1;
            ENDIF

            ! Send a response back to the Python server
            IF auto_mode THEN
            endProces;
            ENDIF
            WaitTime 1.5;
            IF auto_mode THEN
                RobotClienSendMessage("Task completed: " + taske);
            ENDIF
            TPWrite "Sent response to Python server.";
        ELSE
            TPWrite "No command received or error occurred.";
        ENDIF
    ENDWHILE
ENDPROC

    PROC PickBottle()
        WaitTime 0.2;
        IF auto_mode THEN
            ! Insert code for obtaining the coordinates
            x_coordinate:=XPOS;
            y_coordinate:=YPOS;
            ZOrient:=rotation;
            bottle_type:=1;
        ELSE
            TPReadNum x_coordinate,"What is the x-coordinate of the bottle lid?";
            TPReadNum y_coordinate,"What is the y-coordinate of the bottle lid?";
            TPReadNum rotation,"What is the rotation of the bottle lid?";
            TPReadFK bottle_type,"What colour is the bottle?","Red","Blue","Yellow",stEmpty,stEmpty;
        ENDIF
        bottleTarget.trans.x:=0;
        bottleTarget.trans.y:=0;
        IF rotation<180 THEN
            rotation:=rotation+180;
            turn_needed:=TRUE;
        ENDIF
        MoveJ RelTool(OFFS(bottleTarget,x_coordinate,y_coordinate,-200),0,0,0 \Rx:=rotation), v1000, z100, Gripper\WObj:=VisionArea;
		!MoveL r20, v1000, fine, Gripper;
		MoveL RelTool(OFFS(bottleTarget,x_coordinate,y_coordinate,0),0,0,-0 \Rx:=rotation), v1000, fine, Gripper\WObj:=VisionArea;
        !bottleTarget.rot:=orientZYX(rotation,0,0);
        !MoveJ OFFS(bottleTarget,0,0,-100),v1000,z100,Gripper\WObj:=VisionArea;
        !MoveL bottleTarget,v1000,fine,Gripper\WObj:=VisionArea;
        WaitTime 0.2;
        SetDO doValve1,1;
        MoveJ RelTool(OFFS(bottleTarget,x_coordinate,y_coordinate,-200),0,0,-0 \Rx:=rotation), v1000, z100, Gripper\WObj:=VisionArea;
        IF turn_needed THEN
            turnBottle;
            turn_needed:=FALSE;
        ENDIF
        !MoveL OFFS(bottleTarget,0,0,-100),v1000,z100,Gripper\WObj:=VisionArea;
    ENDPROC
    PROC turnBottle()
        MoveJ OFFS(TurnJigBottlePos, -50, 100, 100), v1000, z100, Gripper\WObj:=TurnJig;
        MoveL OFFS(TurnJigBottlePos, -50, 0, 0), v1000, fine, Gripper\WObj:=TurnJig;
        SetDO doValve1,0;
        MoveL OFFS(TurnJigBottlePos, -50, 100, 100), v1000, fine, Gripper\WObj:=TurnJig;
        MoveJ Reltool(OFFS(TurnJigBottlePos, -50, 100, 100),0,0,0\Rx:=180), v1000, z100, Gripper\WObj:=TurnJig;
        MoveL Reltool(OFFS(TurnJigBottlePos, 0, 0, 0),0,0,0\Rx:=180), v1000, z100, Gripper\WObj:=TurnJig;
        SetDO doValve1,1;
        WaitTime 0.2;
        MoveL Reltool(OFFS(TurnJigBottlePos, -50, 0, 0),0,0,0\Rx:=180), v1000, z100, Gripper\WObj:=TurnJig;
        MoveJ Reltool(OFFS(TurnJigBottlePos, -50, 100, 100),0,0,0\Rx:=180), v1000, z100, Gripper\WObj:=TurnJig;
        
    endproc
    PROC PlaceBottle()
        WHILE Container{bottle_type,i}=TRUE DO
            i:=i+1;
        ENDWHILE
        offset:=((i-1) DIV 2) * (-109);
        IF i MOD 2 = 0 THEN
            MoveJ OFFS(Target_Front_Left, 0, offset+container_offset*(bottle_type-1), 400), v1000, z100, Gripper\WObj:=Buffer;
            MoveL OFFS(Target_Front_Left, 0, offset+container_offset*(bottle_type-1), 0), v1000, fine, Gripper\WObj:=Buffer;
            SetDO doValve1, 0;
            MoveL OFFS(Target_Front_Left, 0, offset+container_offset*(bottle_type-1), 400), v1000, z100, Gripper\WObj:=Buffer;
        ELSE
            MoveJ OFFS(Target_Front_Right, 0, offset+container_offset*(bottle_type-1), 400), v1000, z100, Gripper\WObj:=Buffer;
            MoveL OFFS(Target_Front_Right, 0, offset+container_offset*(bottle_type-1), 0), v400, fine, Gripper\WObj:=Buffer;
            SetDO doValve1, 0;
            MoveL OFFS(Target_Front_Right, 0, offset+container_offset*(bottle_type-1), 400), v400, z100, Gripper\WObj:=Buffer;
        ENDIF
        
        Container{bottle_type,i}:=TRUE;
        IF Container{bottle_type,Dim(Container,2)}=TRUE THEN
            full:=TRUE;
        ENDIF
        MoveJ Home_conveyor,v1000,z100,Gripper\WObj:=wobj0;
    ENDPROC

    PROC ContainerSwitcheroo(intnum i)
        !SetDO DO_RequestAGV,1;
            !Move and pick container from the original position
            i:=i-1;
            MoveJ Home_agv,v1000,z100,Gripper\WObj:=wobj0;
            MoveJ OFFS(ContainerFrontPos,container_offset*i,0,200),v1000,z100,Gripper\WObj:=Buffer;
            MoveL OFFS(ContainerFrontPos,container_offset*i,0,0),v1000,fine,Gripper\WObj:=Buffer;
            WaitTime 0.2;
            SetDO doValve1,1;
            MoveL OFFS(ContainerFrontPos,container_offset*i,0,100),v1000,fine,Gripper\WObj:=Buffer;
            MoveJ OFFS(ContainerFrontPos,container_offset*i,580,200),v1000,z100,Gripper\WObj:=Buffer;
            MoveL OFFS(ContainerFrontPos,container_offset*i,580,0),v1000,fine,Gripper\WObj:=Buffer;
            SetDO doValve1, 0;
            MoveL OFFS(ContainerFrontPos,container_offset*i,580,100),v1000,z100,Gripper\WObj:=Buffer;
            !WaitDI DI_AGV_IN_POS,1;
            !SetDO DO_RequestAGV,0;
            MoveJ OFFS(AGV_Container,0,container_offset*i,-100),v1000,z100,Gripper\WObj:=AGV_WOBJ;
            MoveL OFFS(AGV_Container,0,container_offset*i,0),v1000,fine,Gripper\WObj:=AGV_WOBJ;
            WaitTime 0.2;
            SetDO doValve1,1;
            MoveL OFFS(AGV_Container,0,container_offset*i,-100),v1000,z100,Gripper\WObj:=AGV_WOBJ;
            MoveJ OFFS(ContainerFrontPos,container_offset*i,0,100),v1000,z100,Gripper\WObj:=Buffer;
            MoveL OFFS(ContainerFrontPos,container_offset*i,0,0),v1000,fine,Gripper\WObj:=Buffer;
            waittime 0.2;
            SetDO doValve1,0;
            MoveL OFFS(ContainerFrontPos,container_offset*i,0,0),v1000,z100,Gripper\WObj:=Buffer;
            MoveJ OFFS(ContainerFrontPos,container_offset*i,580,100),v1000,z100,Gripper\WObj:=Buffer;
            MoveL OFFS(ContainerFrontPos,container_offset*i,580,0),v1000,fine,Gripper\WObj:=Buffer;
            WaitTime 0.2;
            SetDO doValve1, 1;
            MoveL OFFS(ContainerFrontPos,container_offset*i,580,100),v1000,z100,Gripper\WObj:=Buffer;
            MoveJ OFFS(AGV_Container,0,container_offset*i,-100),v1000,z100,Gripper\WObj:=AGV_WOBJ;
            MoveL OFFS(AGV_Container,0,container_offset*i,0),v1000,fine,Gripper\WObj:=AGV_WOBJ;
            SetDO doValve1,0;
            MoveL OFFS(AGV_Container,0,container_offset*i,-100),v1000,z100,Gripper\WObj:=AGV_WOBJ;
            !SetDO DO_Sent_AGV,1;
            MoveJ Home_conveyor,v1000,z100,tool0\WObj:=wobj0;
            !SetDO DO_Sent_AGV,0;
        !Reset the container contents
            FOR j FROM 1 TO 6 DO
                Container{i+1,j}:=FALSE;
            ENDFOR
    ENDPROC
    
    PROC startProces()
        WaitTime 5;
        WHILE handshake = "TRUE" DO
            RobotClienSendMessage("TRUE");
            command := RobotClientReciveMessage();
            SplitMessage;
            WaitTime 5;
        ENDWHILE
        RobotClienSendMessage("FALSE");
        command := RobotClientReciveMessage();
        SplitMessage;
        WaitTime 2;
    ENDPROC    
    
    
    PROC endProces()
        WaitTime 5;
        WHILE handshake = "FALSE" DO
            RobotClienSendMessage("TRUE");
            command := RobotClientReciveMessage();
            SplitMessage;
            WaitTime 5;
        ENDWHILE
        WHILE handshake = "TRUE" DO
            RobotClienSendMessage("FALSE");
            command := RobotClientReciveMessage();
            SplitMessage;
            WaitTime 2;
        ENDWHILE
    ENDPROC  
    
    
    PROC SplitMessage()
        VAR num foundsemicolon;
    
        ! Find the semicolon position to identify the separator
        foundsemicolon := StrFind(command, 1, ";");
    
        ! Separate the handshake and taske parts of the message
        handshake := StrPart(command, 1, foundsemicolon - 1);
        taske := StrPart(command, foundsemicolon + 1, StrLen(command) - foundsemicolon);
    
        ! Display separated messages for debugging (optional)
        TPWrite "Handshake: " + handshake;
        TPWrite "Taske: " + taske;
        
    ENDPROC
	PROC Routine1()
		TPReadNum reg6, "x";
		TPReadNum reg7, "y";
		TPReadNum reg8, "z";
		TPReadNum reg9, "zzrot";
		MoveJ RelTool(r10,reg6,reg7,reg8\Ry:=reg9), v1000, fine, Gripper;
		!MoveL r20, v1000, fine, Gripper;
		MoveL RelTool(r20,reg6,reg7,reg8\Ry:=reg9), v1000, fine, Gripper;
	ENDPROC
ENDMODULE