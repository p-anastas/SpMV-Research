///
/// \author Anastasiadis Petros (panastas@cslab.ece.ntua.gr)
///
/// \brief A benchmark script for SpMV implementations
///

#include <cstdio>
#include <gpu_utils.hpp>
#include <numeric>
#include <spmv_utils.hpp>
#include "cuSPARSE.hpp"
#include <iostream>
#include <fstream>

#include "nvmlPower.hpp"

int main(int argc, char **argv) {
  /// Check Input
  massert(argc == 10 || argc ==11,
          "Incorrect arguments.\nUsage:  ./Executable logfilename spmv_implementation [blockdim] Mpakos_7_parameters_with_spaces");
                    
  // Set/Check for device
  int device_id = 1;
  cudaSetDevice(device_id);
  cudaGetDevice(&device_id);
  cudaDeviceProp deviceProp;
  cudaGetDeviceProperties(&deviceProp, device_id);
  cout << "Device [" <<  device_id << "] " << deviceProp.name << ", " << " @ " << deviceProp.clockRate * 1e-3f << "MHz. " << endl;
  
  char *outfile = argv[1];
  int impFlag = 0, blockdim = 4, start_of_matrix_generation_args = 3, verbose = 1; /// Default case; run ALL versions (might break)
  void *y_out, *y_out1;
  double cpu_timer, gpu_timer, exc_timer = 0, trans_timer[4] = {0, 0, 0, 0}, gflops_s = -1.0;
  /// Check which version to run!! Important: Names must match strings here
  char* tempstr = argv[2];
  if (strstr(tempstr, "OMP_csr")) impFlag = 1;
  else if (strstr(tempstr, "cuSPARSE_csr")) impFlag = 2;
  else if (strstr(tempstr, "cuSPARSE_hyb")) impFlag = 3;
  else if (strstr(tempstr, "cuSPARSE_bsr")){
    impFlag = 4;
    if(argc == 11){
    	blockdim = atoi(argv[3]);
    	start_of_matrix_generation_args = 4;
    }
  }
  if (!impFlag) fprintf(stderr,"WARNING: Running all implementations might crash due to stuff\n"); 
  
  /// Mix C & C++ file inputs, because...?
  ofstream foutp;
  foutp.open(outfile, ios::out | ios::app ); 
  massert(foutp.is_open() , "Invalid output File");
  // print_devices();
  
  exc_timer = csecond();
  SpmvOperator op(argc, argv, start_of_matrix_generation_args, verbose);
  exc_timer = csecond() - exc_timer;
 
  fprintf(stdout,
      "File=%s ( n=%d m=%d trans=%d n_z=%d Sparsity=%lf ) Input time=%lf s\n",
      op.mtx_name, op.n, op.m, op.count_transactions(), op.nz,
      1.0 * op.nz / op.n / op.m, exc_timer);
  VALUE_TYPE *x = (VALUE_TYPE *)malloc(op.m * sizeof(VALUE_TYPE));
  VALUE_TYPE *out = (VALUE_TYPE *)malloc(op.n * sizeof(VALUE_TYPE));
  vec_init_rand<VALUE_TYPE>(x, op.m, 0);
  op.vec_alloc((VALUE_TYPE*)x);

  SpmvOperator cuSPARSE_op(op);
  cuSPARSE_op.cuSPARSE_init();

  SpmvOperator bsr_op(op);
  bsr_op.cuSPARSE_init();

  //cuSPARSE_op.print_op();
  SpmvOperator openmp_op(cuSPARSE_op);
  openmp_op.format_convert(SPMV_FORMAT_CSR);
  openmp_op.mem_convert(SPMV_MEMTYPE_HOST);
  openmp_op.openmp_init();

#ifdef TEST
  // compare_op(op, cuSPARSE_op);
  // cuSPARSE_op.format_convert(SPMV_FORMAT_CSR);
  // compare_op(cuSPARSE_op, openmp_op);

  fprintf(stdout,"Serial-CSR: ");
  op.timer = csecond();
  SpmvCsrData *data = (SpmvCsrData *)op.format_data;
  spmv_csr<VALUE_TYPE>(data->rowPtr, data->colInd, (VALUE_TYPE *) data->values, (VALUE_TYPE *)op.x,
           (VALUE_TYPE *)op.y, op.n);
  op.timer = csecond() - op.timer;
  report_results(op.timer * NR_ITER, op.flops, op.bytes);
  fprintf(stdout,"\n");

  fprintf(stdout,"\nRunning tests.. \n");

  if (!impFlag || impFlag == 1){
  	fprintf(stdout,"Testing openmp_csr...\t");
  	openmp_op.openmp_csr();
  	check_result<VALUE_TYPE>((VALUE_TYPE *)openmp_op.y, (VALUE_TYPE *)op.y, openmp_op.n);
  }

  /*
  SpmvOperator csr5_op(cuSPARSE_op);
      csr5_op.format_convert(SPMV_FORMAT_CSR);
      csr5_op.cuCSR5_init();
  printf("Testing cuCSR5_csr...");
  csr5_op.cuCSR5_csr();
  cudaDeviceSynchronize();
  check_result<VALUE_TYPE>((VALUE_TYPE *)csr5_op.y, (VALUE_TYPE *)op.y, openmp_op.n);


      SpmvOperator acsr5_op(cuSPARSE_op);
      acsr5_op.format_convert(SPMV_FORMAT_CSR);
      acsr5_op.mem_convert(SPMV_MEMTYPE_HOST);
      acsr5_op.avx512CSR5_init();
  printf("Testing avx512CSR5_csr...");
  acsr5_op.avx512CSR5_csr();
  check_result<VALUE_TYPE>((VALUE_TYPE *)acsr5_op.y, (VALUE_TYPE *)op.y, openmp_op.n);
  */
  if (!impFlag || impFlag == 2){
  	fprintf(stdout,"Testing cuSPARSE_csr...\t");
  	cuSPARSE_op.format_convert(SPMV_FORMAT_CSR);
  	cuSPARSE_op.cuSPARSE_csr();
  	cudaDeviceSynchronize();
  	check_result<VALUE_TYPE>((VALUE_TYPE *)cuSPARSE_op.y, (VALUE_TYPE *)op.y, cuSPARSE_op.n);
  }

  if (!impFlag || impFlag == 3){
  	fprintf(stdout,"Testing cuSPARSE_hyb...\t");
  	cuSPARSE_op.format_convert(SPMV_FORMAT_HYB);
  	cuSPARSE_op.cuSPARSE_hyb();
  	cudaDeviceSynchronize();
  	check_result<VALUE_TYPE>((VALUE_TYPE *)cuSPARSE_op.y, (VALUE_TYPE *)op.y, cuSPARSE_op.n);
  }

  if (!impFlag || impFlag == 4){
  	fprintf(stdout,"Testing cuSPARSE_bsr-%d...\t", blockdim);
  	/// Convert to cuSPARSE bsr
  	bsr_op.bsr_blockDim = blockdim;
  	bsr_op.format_convert(SPMV_FORMAT_BSR);
  	bsr_op.cuSPARSE_bsr();
  	cudaDeviceSynchronize();
  	check_result<VALUE_TYPE>((VALUE_TYPE *)bsr_op.y, (VALUE_TYPE *)op.y, bsr_op.n);
  }

#endif

  if (!impFlag || impFlag == 1){
  	// Warmup
  	for (int i = 0; i < 100; i++) openmp_op.openmp_csr();

  	// Run OpenMP csr
  	int threadNum = get_num_threads(); 
  	fprintf(stdout,"Timing openmp_csr-%d...\n", threadNum);
  	openmp_op.timer = csecond();
  	for (int i = 0; i < NR_ITER; i++) openmp_op.openmp_csr();
  	openmp_op.timer = csecond() - openmp_op.timer;
  	gflops_s = 2*openmp_op.nz*1e-9/openmp_op.timer*NR_ITER;
  	std::cout << argv << "," << "OMP_csr-" << threadNum << "," << openmp_op.m << "," << openmp_op.n << "," << openmp_op.nz << "," << openmp_op.timer << "," << gflops_s << "\n";
  	foutp << argv << "," << "OMP_csr-" << threadNum << "," << openmp_op.m << "," << openmp_op.n << "," << openmp_op.nz << "," << openmp_op.timer << "," << gflops_s << "\n";

  	cpu_timer = openmp_op.timer;
  }

  if (!impFlag || impFlag == 2){
  	/// Run cuSPARSE csr
  	cuSPARSE_op.format_convert(SPMV_FORMAT_CSR);

  	// Warmup
  	for (int i = 0; i < 100; i++) cuSPARSE_op.cuSPARSE_csr();
  	cudaDeviceSynchronize();

  	// Run cuSPARSE csr
  	fprintf(stdout,"Timing cuSPARSE_csr...\n");
  	nvmlAPIRun();
  	cuSPARSE_op.timer = csecond();
  	for (int i = 0; i < NR_ITER; i++) {
    		cuSPARSE_op.cuSPARSE_csr();
    		cudaDeviceSynchronize();
  	}
	cudaCheckErrors();
  	cuSPARSE_op.timer = (csecond() - cuSPARSE_op.timer)/NR_ITER;
  	nvmlAPIEnd();
  	gflops_s = 2*cuSPARSE_op.nz*1e-9/cuSPARSE_op.timer;
  	std::cout << argv << "," << "cuSPARSE_csr" << "," << cuSPARSE_op.m << "," << cuSPARSE_op.n << "," << cuSPARSE_op.nz << "," << cuSPARSE_op.timer << "," << gflops_s << "\n";
  	foutp << argv << "," << "cuSPARSE_csr" << "," << cuSPARSE_op.m << "," << cuSPARSE_op.n << "," << cuSPARSE_op.nz << "," << cuSPARSE_op.timer << "," << gflops_s << "\n";
  }

  if (!impFlag || impFlag == 3){
  	/// Convert to cuSPARSE hyb
  	cuSPARSE_op.format_convert(SPMV_FORMAT_HYB);

  	// Warmup
  	for (int i = 0; i < 100; i++) cuSPARSE_op.cuSPARSE_hyb();
  	cudaDeviceSynchronize();

  	// Run cuSPARSE hyb
  	fprintf(stdout,"Timing cuSPARSE_hyb...\n");
  	nvmlAPIRun();
  	cuSPARSE_op.timer = csecond();
  	for (int i = 0; i < NR_ITER; i++) {
  	  cuSPARSE_op.cuSPARSE_hyb();
  	  cudaDeviceSynchronize();
  	}
	cudaCheckErrors();
  	cuSPARSE_op.timer = (csecond() - cuSPARSE_op.timer)/NR_ITER;
  	nvmlAPIEnd();
  	gflops_s = 2*cuSPARSE_op.nz*1e-9/cuSPARSE_op.timer;
  	std::cout << argv << "," << "cuSPARSE_hyb" << "," << cuSPARSE_op.m << "," << cuSPARSE_op.n << "," << cuSPARSE_op.nz << "," << cuSPARSE_op.timer << "," << gflops_s << "\n";
  	foutp << argv << "," << "cuSPARSE_hyb" << "," << cuSPARSE_op.m << "," << cuSPARSE_op.n << "," << cuSPARSE_op.nz << "," << cuSPARSE_op.timer << "," << gflops_s << "\n";
  }

  if (!impFlag || impFlag == 4){
  	/// Convert to cuSPARSE bsr
  	bsr_op.bsr_blockDim = blockdim;
  	bsr_op.format_convert(SPMV_FORMAT_BSR);

  	// Warmup
  	for (int i = 0; i < 100; i++) bsr_op.cuSPARSE_bsr();
  	cudaDeviceSynchronize();

  	// Run cuSPARSE bsr
  	fprintf(stdout,"Timing cuSPARSE_bsr-%d...\n", blockdim);
  	nvmlAPIRun();
  	bsr_op.timer = csecond();
  	for (int i = 0; i < NR_ITER; i++) {
    		bsr_op.cuSPARSE_bsr();
    		cudaDeviceSynchronize();
  	}
	cudaCheckErrors();
  	bsr_op.timer = (csecond() - bsr_op.timer)/NR_ITER;
  	nvmlAPIEnd();
  	gflops_s = 2*bsr_op.nz*1e-9/bsr_op.timer;
  	std::cout << argv << "," << "cuSPARSE_bsr-" << blockdim << "," << bsr_op.m << "," << bsr_op.n << "," << bsr_op.nz << "," << bsr_op.timer << "," << gflops_s << "\n";
  	foutp << argv << "," << "cuSPARSE_bsr-" << blockdim << "," << bsr_op.m << "," << bsr_op.n << "," << bsr_op.nz << "," << bsr_op.timer << "," << gflops_s << "\n";
  } 

  foutp.close();

}
