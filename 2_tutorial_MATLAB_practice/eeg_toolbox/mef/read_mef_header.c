//
//
// 
// mex read_mef_header.c RED_decode.c RED_encode.c endian_functions.c mef_lib.c AES_encryption.c crc_32.c 
//
//

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "mex.h"
#include "matrix.h"
#include "mef_header.h"
#include "mef_lib.h"
#include "RED_codec.h"

#define BIG_ENDIAN_CODE		0
#define LITTLE_ENDIAN_CODE	1

void read_mef_header(char *f_name, MEF_HEADER_INFO *hdr_info, char *password)
{
	char			*c, *comp_data;
	unsigned char		*header, cpu_endianness();
	unsigned int		n_read;
	unsigned int		i;
	FILE			*fp;
	
	/* get cpu endianness */
	if (cpu_endianness() != LITTLE_ENDIAN_CODE) {
		mexErrMsgTxt("[read_mef_header] is currently only compatible with little-endian machines => exiting");
		return;
	}
	
	/* read header */
	fp = fopen(f_name, "r");
	if (fp == NULL) { 
		printf("[read_mef_header] could not open the file \"%s\" => exiting\n",  f_name);
		return;
	}
	header = (unsigned char *) malloc(MEF_HEADER_LENGTH);  // malloc to ensure boundary alignment
	n_read = fread((void *) header, sizeof(char), (size_t) MEF_HEADER_LENGTH, fp);
	if (n_read != MEF_HEADER_LENGTH) {
		printf("[read_mef_header] error reading the file \"%s\" => exiting\n",  f_name);
		return;
	}	
	if ((read_mef_header_block(header, hdr_info, password))) {
		printf("[read_mef_header] header read error for file \"%s\" => exiting\n", f_name);
		return;		
	}
	free(header);
	
	/* get file endianness */
	if (hdr_info->byte_order_code != LITTLE_ENDIAN_CODE) {
		mexErrMsgTxt("[read_mef_header] is currently only compatible with little-endian files (file \"%s\") => exiting");
		return;
	}

	return;
}


// The mex gateway routine 
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char		*f_name, *password;
	unsigned char *ucp;
	mxArray		*fout;
	const mwSize	dims[] = {1,8};
	int			buf_len, status, i, hdr_struct_len;
	unsigned long long int	start_idx, end_idx, long_decomp_data_len;
	void			read_mef_header();
	MEF_HEADER_INFO header;
    //set up field names:
	const char		*fnames[] = {	
        "institution",              //0
        "unencrypted_text_field",   //1
        "encryption_algorithm",     //2
		"subject_encryption_used",  //3
        "session_encryption_used",  //4
        "data_encryption_used",     //5
        "byte_order_code",          //6
		"header_version_major",     //7
        "header_version_minor",     //8
        "session_unique_ID",        //9
        "header_length",            //10
		"subject_first_name",       //11
        "subject_second_name",      //12
        "subject_third_name",       //13
        "subject_id",               //14
        "session_password",         //15
		"number_of_samples",        //16
        "channel_name",             //17
        "recording_start_time",     //18
        "recording_end_time",       //19
        "sampling_frequency",       //20
		"low_frequency_filter_setting", //21
        "high_frequency_filter_setting", //22
        "notch_filter_frequency",   //23
		"voltage_conversion_factor", //24
        "acquisition_system",       //25
        "channel_comments",         //26
        "study_comments",           //27
		"physical_channel_number",  //28
        "compression_algorithm",    //29
        "maximum_compressed_block_size", //30
        "maximum_block_length",     //31
		"block_interval",           //32
        "maximum_data_value",       //33
        "minimum_data_value",       //34
        "index_data_offset",        //35
        "number_of_index_entries",	//36
        "block_header_length"       //37
        };	

	//  Check for proper number of arguments 
	if (nrhs != 2) 
		mexErrMsgTxt("[read_mef_header] two inputs required: file_name, password");
	if (nlhs != 1) 
		mexErrMsgTxt("[read_mef_header] one output required: header_structure");
	
	// get the input file name (argument 1)
	if (mxIsChar(prhs[0]) != 1) { // Check to make sure the first input argument is a string 
		mexErrMsgTxt("[read_mef_header] file name must be a string => exiting");
		return;
	}		
	buf_len = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 2; // Get the length of the input string 
	f_name = malloc(buf_len); // Allocate memory for file_name string
	status = mxGetString(prhs[0], f_name, buf_len);
	if (status != 0) {
		mexWarnMsgTxt("[read_mef_header] not enough space for input file name string => exiting");
		return;
	}
	
   //check for compile with correct datatype definitions
    if (sizeof(ui8) != 8 || sizeof(si8) !=8) {
        mexErrMsgTxt("[read_mef_header] Warning: MEX function was not compiled with 8-byte integers. Incorrect information is probable.");
    }

	// get the password (argument 2)
	if (mxIsChar(prhs[1]) != 1) { // Check to make sure the fourth input argument is a string 
		mexErrMsgTxt("[read_mef_header] Password must be a stringx => exiting");
		return;
	}	
	buf_len = (mxGetM(prhs[1]) * mxGetN(prhs[1])) + 2; // Get the length of the input string 
	password = malloc(buf_len); // Allocate memory for file_name string
	status = mxGetString(prhs[1], password, buf_len);
	if (status != 0) {
		mexErrMsgTxt("[read_mef_header] not enough space for password string => exiting");
		return;
	}

	// Set the output pointer to the output matrix. 
	hdr_struct_len = sizeof(MEF_HEADER_INFO);
	if (hdr_struct_len >= (unsigned long long int) (1 << 31)) {
		mexErrMsgTxt("[read_mef_header] requested memory exceeds Matlab limit => exiting");
		return;
	}	
	
    memset(&header, 0, sizeof(MEF_HEADER_INFO)); //this avoids gibberish in the output header if an error is encountered during read
    
	// Call the C subroutine. 
	read_mef_header(f_name, &header, password);
	
	//create output structure
	plhs[0] = mxCreateStructMatrix(1, 1, 38, fnames);
	
   
	
	//populate structure with header information
	fout = mxCreateString(header.institution);
	mxSetFieldByNumber(plhs[0], 0, 0, fout);
	
	fout = mxCreateString(header.unencrypted_text_field);
	mxSetFieldByNumber(plhs[0], 0, 1, fout);
	
	fout = mxCreateString(header.encryption_algorithm);
	mxSetFieldByNumber(plhs[0], 0, 2, fout);
	
	fout = mxCreateLogicalScalar(header.subject_encryption_used);
	mxSetFieldByNumber(plhs[0], 0, 3, fout);
	
	fout = mxCreateLogicalScalar(header.session_encryption_used);
	mxSetFieldByNumber(plhs[0], 0, 4, fout);
	
	fout = mxCreateLogicalScalar(header.data_encryption_used);
	mxSetFieldByNumber(plhs[0], 0, 5, fout);

	if (header.byte_order_code) fout = mxCreateString("little-endian");
	else fout = mxCreateString("big-endian");
	mxSetFieldByNumber(plhs[0], 0, 6, fout);
	
	fout = mxCreateDoubleScalar((double)header.header_version_major);
	mxSetFieldByNumber(plhs[0], 0, 7, fout);

	fout = mxCreateDoubleScalar((double)header.header_version_minor);
	mxSetFieldByNumber(plhs[0], 0, 8, fout);
	
	fout = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL); /////// fill in values here-----
	ucp = (unsigned char *)mxGetData(fout);
	for (i=0; i<8; i++) ucp[i] = header.session_unique_ID[i];
	mxSetFieldByNumber(plhs[0], 0, 9, fout);

	fout = mxCreateDoubleScalar((double)header.header_length);
	mxSetFieldByNumber(plhs[0], 0, 10, fout);

	fout = mxCreateString(header.subject_first_name);
	mxSetFieldByNumber(plhs[0], 0, 11, fout);
	
	fout = mxCreateString(header.subject_second_name);
	mxSetFieldByNumber(plhs[0], 0, 12, fout);	
	
	fout = mxCreateString(header.subject_third_name);
	mxSetFieldByNumber(plhs[0], 0, 13, fout);	
	
	fout = mxCreateString(header.subject_id);
	mxSetFieldByNumber(plhs[0], 0, 14, fout);	
	
	fout = mxCreateString(header.session_password);
	mxSetFieldByNumber(plhs[0], 0, 15, fout);	
	
	fout = mxCreateDoubleScalar((double)header.number_of_samples);
	mxSetFieldByNumber(plhs[0], 0, 16, fout);
	
	fout = mxCreateString(header.channel_name);
	mxSetFieldByNumber(plhs[0], 0, 17, fout);
	
	fout = mxCreateDoubleScalar((double)header.recording_start_time);
	mxSetFieldByNumber(plhs[0], 0, 18, fout);
	
	fout = mxCreateDoubleScalar((double)header.recording_end_time);
	mxSetFieldByNumber(plhs[0], 0, 19, fout);
	
	fout = mxCreateDoubleScalar(header.sampling_frequency);
	mxSetFieldByNumber(plhs[0], 0, 20, fout);
	
	fout = mxCreateDoubleScalar(header.low_frequency_filter_setting);
	mxSetFieldByNumber(plhs[0], 0, 21, fout);
	
	fout = mxCreateDoubleScalar(header.high_frequency_filter_setting);
	mxSetFieldByNumber(plhs[0], 0, 22, fout);
	
	fout = mxCreateDoubleScalar(header.notch_filter_frequency);
	mxSetFieldByNumber(plhs[0], 0, 23, fout);
	
	fout = mxCreateDoubleScalar(header.voltage_conversion_factor);
	mxSetFieldByNumber(plhs[0], 0, 24, fout);
	
	fout = mxCreateString(header.acquisition_system);
	mxSetFieldByNumber(plhs[0], 0, 25, fout);
	
	fout = mxCreateString(header.channel_comments);
	mxSetFieldByNumber(plhs[0], 0, 26, fout);
	
	fout = mxCreateString(header.study_comments);
	mxSetFieldByNumber(plhs[0], 0, 27, fout);
	
	fout = mxCreateDoubleScalar((double)header.physical_channel_number);
	mxSetFieldByNumber(plhs[0], 0, 28, fout);
	
	fout = mxCreateString(header.compression_algorithm);
	mxSetFieldByNumber(plhs[0], 0, 29, fout);
	
	fout = mxCreateDoubleScalar((double)header.maximum_compressed_block_size);
	mxSetFieldByNumber(plhs[0], 0, 30, fout);

	fout = mxCreateDoubleScalar((double)header.maximum_block_length);
	mxSetFieldByNumber(plhs[0], 0, 31, fout);
	
	fout = mxCreateDoubleScalar((double)header.block_interval);
	mxSetFieldByNumber(plhs[0], 0, 32, fout);
	
	fout = mxCreateDoubleScalar((double)header.maximum_data_value);
	mxSetFieldByNumber(plhs[0], 0, 33, fout);

	fout = mxCreateDoubleScalar((double)header.minimum_data_value);
	mxSetFieldByNumber(plhs[0], 0, 34, fout);
	
	fout = mxCreateDoubleScalar((double)header.index_data_offset);
	mxSetFieldByNumber(plhs[0], 0, 35, fout);
	
	fout = mxCreateDoubleScalar((double)header.number_of_index_entries);
	mxSetFieldByNumber(plhs[0], 0, 36, fout);
	
	fout = mxCreateDoubleScalar((double)header.block_header_length);
	mxSetFieldByNumber(plhs[0], 0, 37, fout);
    
	free(f_name);
	free(password);
	
	return;
} 
