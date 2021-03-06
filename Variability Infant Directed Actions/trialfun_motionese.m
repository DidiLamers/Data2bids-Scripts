function trl = trialfun_motionese(cfg)

% Read relevant info
event = ft_read_event(cfg.dataset);
hdr   = ft_read_header(cfg.dataset);

% Initiate the output struct
counttrial = 0;
blck = 1;

% Generate vectors containing info on markers
intro_balls = {'S101', 'S102', 'S103', 'S104', 'S105', 'S106'};
intro_cups  = {'S107', 'S108', 'S109', 'S110', 'S111', 'S112'};
intro_rings = {'S113', 'S114', 'S115', 'S116', 'S117', 'S118'};

exp_balls = {'S201', 'S202', 'S203', 'S204', 'S205', 'S206'};
exp_cups  = {'S207', 'S208', 'S209', 'S210', 'S211', 'S212'};
exp_rings = {'S213', 'S214', 'S215', 'S216', 'S217', 'S218'};

load(['Additional_Info' filesep 'EEG_Trigger' filesep 'later_coded_from_stimuli' filesep 'stim_videos_msec_info_actiongoals.mat']);
timing_action = stim_videos_msec_info_actiongoals;
pre_stim_samples = round(1.5  * hdr.Fs); % A pre-stim period of 1.5 s
post_stim_samples = round(1 * hdr.Fs); % A post-stim period of 1 s

% There are strange Markers in some subject, we remove these
array = logical(zeros(size(event,2),1));
for ii = 2:size(event, 2)-1
    if strcmp(event(ii).type, cfg.trialdef.eventtype)
        value = sum(str2double(regexp(event(ii).value,'\d+','match')));        
        if value>118 && value<201
            % this marker is meaningless, we remove it
            array(ii,1) = 1;
        elseif value>218
            % this marker is meaningless, we remove it
            array(ii,1) = 1;            
        end
        if sum(str2double(regexp(event(ii-1).value,'\d+','match')))>=101 && sum(str2double(regexp(event(ii-1).value,'\d+','match')))<=118
            if sum(str2double(regexp(event(ii+1).value,'\d+','match')))>=201 && sum(str2double(regexp(event(ii+1).value,'\d+','match')))<=218
                % Then we are in between an intro and exp video, there
                % should be nothing here
                if value>100
                    array(ii,1)=1;
                end
            end
        end
        if sum(str2double(regexp(event(ii-1).value,'\d+','match')))>=201 && sum(str2double(regexp(event(ii-1).value,'\d+','match')))<=218
            if sum(str2double(regexp(event(ii+1).value,'\d+','match')))<=34
                % Then we are in between an exp video en condition indicator, there
                % should be nothing here
                if value>100
                    array(ii,1)=1;
                end
            end
        end
    end
end
event(array) = [];

% Now let's loop over all events
for ii = 1:size(event,2)
    % First we test if it is an event of interest
    if strcmp(event(ii).type, cfg.trialdef.eventtype)
            % Then it is a stimulus of interest
        
            % Then we test for all possible trials
            if strcmp(event(ii).value, 'S 95')
                    if ii == size(event,2)
                    % somehow the last trigger is a fixation cross,we ignore it
                    else
                        % It is a new fixation cross trial
                        counttrial = counttrial + 1;        
                        begsample(counttrial, :) = event(ii).sample; % Start sample number of the event              
                        endsample(counttrial, :) = event(ii+1).sample-1;  
                        offset(counttrial, :) = 0;
                        block(counttrial, : ) = blck;
                        marker(counttrial, : ) = {event(ii).value};
                        stimulus(counttrial, : ) = {'fixation cross'};
                        action_exp_video(counttrial, : ) = {'n/a'};
                        condition_exp_video(counttrial, :) = {'n/a'};                                     
                    end
            
            elseif sum(str2double(regexp(event(ii).value,'\d+','match')))>=101 && sum(str2double(regexp(event(ii).value,'\d+','match')))<=118
                    % It's an intro video
                    counttrial = counttrial + 1;           
                    % Here we can test whether it is a new block
                    if ii>3
                        previous = sum(str2double(regexp(event(ii-2).value,'\d+','match')));
                        if previous>80 && previous<90
                            % the previous video was a peek-a-boo, this is a
                            % new block
                            blck = blck+1;
                            % the previous fixation cross is also a new
                            % block
                            block(counttrial-1, :) = blck;
                        end
                    end
                    begsample(counttrial, :) = event(ii).sample; % Start sample number of the event              
                    endsample(counttrial, :) = event(ii+1).sample-1;  
                    offset(counttrial, :) = 0;
                    block(counttrial, : ) = blck;
                    marker(counttrial, : ) = {event(ii).value};
                    if any(strcmp(event(ii).value, intro_balls))
                        stimulus(counttrial, : ) = {'motionese_intro_balls_hellobaby'};
                    elseif any(strcmp(event(ii).value, intro_cups))
                        stimulus(counttrial, : ) = {'motionese_intro_cups_hellobaby'};
                    elseif any(strcmp(event(ii).value, intro_rings))
                        stimulus(counttrial, : ) = {'motionese_intro_rings_hellobaby'};
                    end                    
                    action_exp_video(counttrial, : ) = {'n/a'};
                    condition_exp_video(counttrial, :) = {'n/a'};                  
                
            elseif sum(str2double(regexp(event(ii).value,'\d+','match')))>200 && sum(str2double(regexp(event(ii).value,'\d+','match')))<220
                    % It's an experimental video
                    counttrial = counttrial + 1;
                    % Let's find start, end, offset, and block
                    begsample(counttrial, :) = event(ii).sample; % Start sample number of the event  
                    duration_experiment = round(32 * hdr.Fs);              
                    endsample(counttrial, :) = begsample(counttrial, :)+duration_experiment; % ask correct durations to Marlene
                    offset(counttrial, :) = 0;
                    block(counttrial, : ) = blck;
                    marker(counttrial, : ) = {event(ii).value};
                    cond = sum(str2double(regexp(event(ii+1).value,'\d+','match')));
                    if any(strcmp(event(ii).value, exp_balls))
                        action_exp_video(counttrial, : ) = {'balls'};
                        if cond == 1
                            condition_exp_video(counttrial, : ) = {'normal'};                            
                            stimulus(counttrial, : ) = {'motionese_stackballs_norm'};
                        elseif cond == 2
                            condition_exp_video(counttrial, : ) = {'high'};
                            stimulus(counttrial, : )  = {'motionese_stackballs_high'};
                        elseif cond == 31
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackballs_var1'};
                        elseif cond == 32
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackballs_var2'};
                        elseif cond == 33
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackballs_var3'};
                        elseif cond == 34
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackballs_var4'};
                        end
                            
                    elseif any(strcmp(event(ii).value, exp_cups))
                        action_exp_video(counttrial, : ) = {'cups'};
                        if cond == 1
                            condition_exp_video(counttrial, : ) = {'normal'};                            
                            stimulus(counttrial, : ) = {'motionese_stackcups_norm'};
                        elseif cond == 2
                            condition_exp_video(counttrial, : ) = {'high'};
                            stimulus(counttrial, : )  = {'motionese_stackcups_high'};
                        elseif cond == 31
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackcups_var1'};
                        elseif cond == 32
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackcups_var2'};
                        elseif cond == 33
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackcups_var3'};
                        elseif cond == 34
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackcups_var4'};
                        end
                        
                    elseif any(strcmp(event(ii).value, exp_rings))
                        action_exp_video(counttrial, : ) = {'rings'};
                        if cond == 1
                            condition_exp_video(counttrial, : ) = {'normal'};                            
                            stimulus(counttrial, : ) = {'motionese_stackrings_norm'};
                        elseif cond == 2
                            condition_exp_video(counttrial, : ) = {'high'};
                            stimulus(counttrial, : )  = {'motionese_stackrings_high'};
                        elseif cond == 31
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackrings_var1'};
                        elseif cond == 32
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackrings_var2'};
                        elseif cond == 33
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackrings_var3'};
                        elseif cond == 34
                            condition_exp_video(counttrial, : ) = {'variable'};
                            stimulus(counttrial, : )  = {'motionese_stackrings_var4'};
                        end
                        
                    end
                    
                    % After each exp video we want to creat 5 extra stimuli, corresponding to each action completed
                    idx = sum(str2double(regexp(event(ii).value,'\d+','match')))-200;
                    % loop over 5 actions
                    for cc = 5:9
                        counttrial = counttrial+1;
                        sample_action = round(timing_action(idx, cc) * hdr.Fs);
                        begsample(counttrial, :) = (event(ii).sample + sample_action) - pre_stim_samples;            
                        endsample(counttrial, :) = (event(ii).sample + sample_action) + post_stim_samples; 
                        offset(counttrial, :) = pre_stim_samples;
                        block(counttrial, : ) = blck;
                        marker(counttrial, : ) = {'n/a'};
                        stimulus(counttrial, : ) = {stimulus(counttrial-(cc-5)-1, :)};
                        action_str = [action_exp_video{counttrial-(cc-5)-1, :} '_stack_' num2str(cc-4) '_completed'];
                        action_exp_video(counttrial, : ) = {action_str};
                        condition_exp_video(counttrial, :) = {condition_exp_video(counttrial-(cc-5)-1, :)};  
                    end
            
            elseif sum(str2double(regexp(event(ii).value,'\d+','match')))>80 && sum(str2double(regexp(event(ii).value,'\d+','match')))<90
                    % It is a peek-a-boo
                    counttrial = counttrial + 1; 
                    
                    % Let's test whether this is a new block
                    previous = sum(str2double(regexp(event(ii-2).value,'\d+','match')));
                    before_previous = sum(str2double(regexp(event(ii-4).value,'\d+','match')));
                    if previous>80 && previous<90 
                        if before_previous == 31 || before_previous == 32 || before_previous == 33 ||...
                                before_previous == 34 || before_previous == 1 || before_previous == 2
                            % Then the last block of only peek-a-boo's started
                            blck = blck+1;
                            % the previous fixation cross is also a new block
                            block(counttrial-1, :) = blck;
                        end
                    end
                    
                    begsample(counttrial, :) = event(ii).sample; % Start sample number of the event
                    videosec = sum(str2double(regexp(event(ii).value,'\d+','match'))) - 80;
                    videotime = (videosec-1)+6.375;
                    videosample = round(videotime * hdr.Fs);
                    endsample(counttrial, :) = begsample(counttrial, :) + videosample;  
                    offset(counttrial, :) = 0;
                    block(counttrial, : ) = blck;
                    marker(counttrial, : ) = {event(ii).value};
                    if sum(str2double(regexp(event(ii).value,'\d+','match')))==81
                        stimulus(counttrial, : ) = {'motionese_intro_peekaboo_1s'};
                    elseif sum(str2double(regexp(event(ii).value,'\d+','match')))==82
                        stimulus(counttrial, : ) = {'motionese_intro_peekaboo_2s'};
                    elseif sum(str2double(regexp(event(ii).value,'\d+','match')))==83
                        stimulus(counttrial, : ) = {'motionese_intro_peekaboo_3s'};
                    elseif sum(str2double(regexp(event(ii).value,'\d+','match')))==84
                        stimulus(counttrial, : ) = {'motionese_intro_peekaboo_4s'};
                    end
                    action_exp_video(counttrial, : ) = {'n/a'};
                    condition_exp_video(counttrial, :) = {'n/a'};        
            
            end 
    end
end


trl = table(begsample, endsample, offset, block, marker, stimulus, action_exp_video, condition_exp_video);