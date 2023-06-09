fprintf([...
    'VOXTOOL:\n ',...
    'voxTool is split into two main windows \n',...
    '\t voxToolHome: Input of the parameters to be used in taliaraching \n',...
    '\t\t as well as the steps taken in post (and soon pre-) processing. \n',...
    '\t voxToolControl: The 3D taliaraching application that allows for \n',...
    '\t\t point and click processing of the EEG data.\n\n',...
    'To create vox_coords_mother.txt for a given patient:\n',...
    'Start up voxTool by typing voxTool into the matlab command prompt\n\n',...
    'NOTE: For now, it is best to enter the information from top to bottom\n',...
    'rather than jumping around.\n\n',...
    'Enter the CT directory (the directory containing the CT dicoms) by \n',...
    'clicking the "CT directory" button and selecting the relevant folder.\n\n',...
    'Enter the MRI directory in the same fashion (not used at the moment,\n',...
    'but still necessary to run the localization program)\n\n',...
    'Subject directory should point to the outer level directory of the \n',...
    'subject (e.g. /data/eeg/TJ061)\n',...
    'Source directory will generally be the same as subject directory\n\n',...
    'Subject Name and Subject Source will generally be the same (e.g. TJ061)\n',...
    'After filling out these fields, Localize Electrodes should be clickable\n',...
    '\n-----------------------\n',...
    'After clicking "Localize Electrodes", voxToolControl will open \n\n',...
    'NOTE: as a result of the way in which the program is written, the \n',...
    'matlab command prompt is unavailable for the period of time in which \n',...
    'voxToolControl is open \n\n'...
    'Load Image will allow you to select a .img file to be taliarached\n',...
    'This process can take anywhere from 30 seconds to around 3 minutes.\n\n',...
    'Load Dicoms is no longer necessary to use, as you specify the CT \n',...
    'directory on the previous screen\n\n',...
    'Load/Save .mat provides a slightly quicker way to load in data that \n'...
    'has previously been loaded into voxTool. Saving a file as .mat should \n',...
    'save all of the progress that has been made in that taliarach session\n',...
    'NOTE: this has not been thoroughly tested.\n\n',...
    'After the img file (or .mat file) has been selected, two new windows \n',...
    'will appear (voxTool3DCT and voxToolDicoms).\n\n',....
    '\n-----------------------\n',...
    'TYPICAL TALIARACHING PROTOCOL:\n\n',...
    'If desired, use the sliders at the bottom of the screen to isolate an \n',...
    'area of the brain that contains the electrodes of interest. \n',...
    '\tLeftmost sliders: rostral/caudal\n',...
    '\tMiddle sliders: lateral/medial\n',...
    '\tRightmost sliders: dorsal/ventral\n\n',...
    'NOTE: If the camera is in orbit/zoom mode, after using the sliders it\n',...
    'will appear as though the camera is still in that mode. This is not the \n',...
    'case. Double click on the orbit/zoom button to fix this problem\n\n',...
    'Use the camera toolbar at the top of the 3DCT window to rotate the \n',...
    'CT into a position where you can clearly make out a row.\n',...
    'Important camera toolbar buttons are, from left to right:\n',...
    '\t1) orbit camera - allows for rotation of the image\n',...
    '\t3/4) Move camera - both horizontal and vertical panning\n',...
    '\t5/6) Zooming - moves the camera closer or further from the image\n\n',...
    'After getting the electrode strip into the desired position, click the \n',...
    'camera control button again to return to selection mode.\n\n',...
    'Select whether the electrode of interest is Depth or Surface on the \n',...
    '"Electrode Type" panel of voxToolControl.\n\n',...
    'Select the dimensions of the electrode with the drop-down menu underneath\n',...
    'the "Electrode Type" panel\n\n',...
    'Check "Select Multiple" if you wish to mark several electrodes at once \n',...
    '(recommended)\n',...
    'Hit "clear" if electrodes have previously been selected\n\n',...
    'Select electrodes in a single strip, starting from the lowest unannotated\n',...
    'number. Moving the camera or assigning electrodes partway through a strip\n',...
    'is fine - it will continue assigning at the number where you left off\n\n',...
    'Type into the "Electrode Name" field the basename of the electrode that \n',...
    'you want to assign. It will automatically append the numbers to the \n',...
    'end of that name.\n\n',...
    'NOTE: For now, do not attempt to use the unassigned electrodes list (on left)\n',...
    'to select which electrodes to assign\n\n',...
    'NOTE: VoxTool will not let you assign more electrodes to a strip than \n',...
    'exist electrodes on that strip, nor will it allow you to change the strip\n',...
    'size mid-strip. You must delete all existing electrodes in that strip, \n',...
    'then reassign to change electrode size\n\n',...
    'Assign all electrodes in this manner, then save vox_coords_mother.txt \n',...
    'to the desired location, and close voxToolControl.\n\n',...
    '\n----------------------------\n',...
    'Post-processiong to come.\n\n'])