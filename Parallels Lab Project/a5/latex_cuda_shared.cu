__device__ int get_tid(){
	return blockIdx.x * blockDim.x + threadIdx.x; /* TODO: copy me from naive version... */
}

/* square of Euclid distance between two multi-dimensional points using column-base format */
	__host__ __device__ inline static
double euclid_dist_2_transpose(int numCoords,
		int    numObjs,
		int    numClusters,
		double *objects,     // [numCoords][numObjs]
		double *clusters,    // [numCoords][numClusters]
		int    objectId,
		int    clusterId)
{
	int i;
	double ans=0.0;

	/* TODO: Copy me from transpose version*/

	/* TODO: Calculate the euclid_dist of elem=objectId of objects from elem=clusterId from clusters, but for column-base format!!! */
	for (i = 0; i < numCoords; i++)
		ans += (objects[i*numObjs + objectId] - clusters[i*numClusters + clusterId]) *
			(objects[i*numObjs + objectId] - clusters[i*numClusters + clusterId]);

	return(ans);
}
	__global__ static
void find_nearest_cluster(int numCoords,
		int numObjs,
		int numClusters,
		double *objects,           //  [numCoords][numObjs]
		double *deviceClusters,    //  [numCoords][numClusters]
		int *deviceMembership,          //  [numObjs]
		double *devdelta)
{
	extern __shared__ double shmemClusters[];

	/* TODO: Copy deviceClusters to shmemClusters so they can be accessed faster. 
BEWARE: Make sure operations is complete before any thread continues... */
	for (int i = 0; i < numClusters; i++) {
		for (int j = 0; j < numCoords; j++) {
			shmemClusters[j * numClusters + i] = deviceClusters[j * numClusters + i];
		}
	}

	__syncthreads();

	/* Get the global ID of the thread. */
	int tid = get_tid(); 

	/* TODO: Maybe something is missing here... should all threads run this? */
	if (tid < numObjs) { // was 1
		int   index, i;
		double dist, min_dist;

		/* find the cluster id that has min distance to object */
		index = 0;
		/* TODO: call min_dist = euclid_dist_2(...) with correct objectId/clusterId */
		min_dist = euclid_dist_2_transpose(numCoords, numObjs, numClusters, objects, shmemClusters, tid, 0); // was empty

		for (i=1; i<numClusters; i++) {
			/* TODO: call dist = euclid_dist_2(...) with correct objectId/clusterId */
			dist = euclid_dist_2_transpose(numCoords, numObjs, numClusters, objects, shmemClusters, tid, i); // was empty

			/* no need square root */
			if (dist < min_dist) { /* find the min and its array index */
				min_dist = dist;
				index    = i;
			}
		}

		if (deviceMembership[tid] != index) {
			/* TODO: Maybe something is missing here... is this write safe? */
			atomicAdd(devdelta, 1.0); // was (*devdelta)+= 1.0;
		}

		/* assign the deviceMembership to object objectId */
		deviceMembership[tid] = index;
	}
}
...
/*	Define the shared memory needed per block.
	- BEWARE: We can overrun our shared memory here if there are too many
	clusters or too many coordinates! 
	- This can lead to occupancy problems or even inability to run. 
	- Your exercise implementation is not requested to account for that (e.g. always assume deviceClusters fit in shmemClusters */
const unsigned int clusterBlockSharedDataSize = numClusters*numCoords*sizeof(double);
...
do {
	timing_internal = wtime(); 
	/* GPU part: calculate new memberships */
#ifdef TIMER_ANALYSIS
	time_start = wtime();
#endif
	/* TODO: Copy clusters to deviceClusters
	   checkCuda(cudaMemcpy(...)); */
	checkCuda(cudaMemcpy(deviceClusters, dimClusters[0],
				clusterBlockSharedDataSize, cudaMemcpyHostToDevice));

	checkCuda(cudaMemset(dev_delta_ptr, 0, sizeof(double)));          
#ifdef TIMER_ANALYSIS
	TIME(cpu_gpu_time);
#endif
	//printf("Launching find_nearest_cluster Kernel with grid_size = %d, block_size = %d, shared_mem = %d KB\n", numClusterBlocks, numThreadsPerClusterBlock, clusterBlockSharedDataSize/1000);
	find_nearest_cluster
		<<< numClusterBlocks, numThreadsPerClusterBlock, clusterBlockSharedDataSize >>>
		(numCoords, numObjs, numClusters,
		 deviceObjects, deviceClusters, deviceMembership, dev_delta_ptr);

	cudaDeviceSynchronize(); checkLastCudaError();
	//printf("Kernels complete for itter %d, updating data in CPU\n", loop);
#ifdef TIMER_ANALYSIS
	TIME(gpu_time);
#endif
	/* TODO: Copy deviceMembership to membership
	   checkCuda(cudaMemcpy(...)); */
	checkCuda(cudaMemcpy(membership, deviceMembership,
				numObjs*sizeof(int), cudaMemcpyDeviceToHost));

	/* TODO: Copy dev_delta_ptr to &delta
	   checkCuda(cudaMemcpy(...)); */
	checkCuda(cudaMemcpy(&delta, dev_delta_ptr,
				sizeof(double), cudaMemcpyDeviceToHost));
#ifdef TIMER_ANALYSIS
	TIME(gpu_cpu_time);
#endif
	/* CPU part: Update cluster centers*/
	for (i=0; i<numObjs; i++) {
		/* find the array index of nestest cluster center */
		index = membership[i];

		/* update new cluster centers : sum of objects located within */
		newClusterSize[index]++;
		for (j=0; j<numCoords; j++)
			newClusters[j][index] += objects[i*numCoords + j];
	}
	/* average the sum and replace old cluster centers with newClusters */
	for (i=0; i<numClusters; i++) {
		for (j=0; j<numCoords; j++) {
			if (newClusterSize[i] > 0)
				dimClusters[j][i] = newClusters[j][i] / newClusterSize[i];
			newClusters[j][i] = 0.0;   /* set back to 0 */
		}
		newClusterSize[i] = 0;   /* set back to 0 */
	}
	delta /= numObjs;
	loop++;
	...
} while (delta > threshold && loop < loop_threshold);

/*TODO: Update clusters using dimClusters. Be carefull of layout!!! clusters[numClusters][numCoords] vs dimClusters[numCoords][numClusters] */
for (i = 0; i < numCoords; i++) {
	for (j = 0; j < numClusters; j++) {
		clusters[j*numCoords + i] = dimClusters[i][j];
	}
}

