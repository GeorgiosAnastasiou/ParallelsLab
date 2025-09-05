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
		int *membership,          //  [numObjs]
		double *devdelta)
{
	/* TODO: copy me from naive version... */

	/* Get the global ID of the thread. */
	int tid = get_tid(); 

	/* TODO: Maybe something is missing here... should all threads run this? */
	if (tid < numObjs) { // was 1
		int   index, i;
		double dist, min_dist;

		/* find the cluster id that has min distance to object */
		index = 0;
		/* TODO: call min_dist = euclid_dist_2(...) with correct objectId/clusterId */
		min_dist = euclid_dist_2_transpose(numCoords, numObjs, numClusters, objects, deviceClusters, tid, 0); // was empty

		for (i=1; i<numClusters; i++) {
			/* TODO: call dist = euclid_dist_2(...) with correct objectId/clusterId */
			dist = euclid_dist_2_transpose(numCoords, numObjs, numClusters, objects, deviceClusters, tid, i); // was empty

			/* no need square root */
			if (dist < min_dist) { /* find the min and its array index */
				min_dist = dist;
				index    = i;
			}
		}

		if (membership[tid] != index) {
			/* TODO: Maybe something is missing here... is this write safe? */
			atomicAdd(devdelta, 1.0); // was (*devdelta)+= 1.0;
		}

		/* assign the deviceMembership to object objectId */
		membership[tid] = index;
	}
}
...
/* TODO: Transpose dims */
double  **dimObjects = NULL; //calloc_2d(...) -> [numCoords][numObjs]
double  **dimClusters = NULL;  //calloc_2d(...) -> [numCoords][numClusters]
double  **newClusters = NULL;  //calloc_2d(...) -> [numCoords][numClusters]
dimObjects  = (double**) calloc_2d(numCoords, numObjs, sizeof(double));
dimClusters = (double**) calloc_2d(numCoords, numClusters, sizeof(double));
newClusters = (double**) calloc_2d(numCoords, numClusters, sizeof(double));
...

//  TODO: Copy objects given in [numObjs][numCoords] layout to new
//  [numCoords][numObjs] layout
for (i = 0; i < numCoords; i++) {
	for (j = 0; j < numObjs; j++) {
		dimObjects[i][j] = objects[j*numCoords + i];
	}
}
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
				numClusters*numCoords*sizeof(double), cudaMemcpyHostToDevice));

	checkCuda(cudaMemset(dev_delta_ptr, 0, sizeof(double)));          

#ifdef TIMER_ANALYSIS
	TIME(cpu_gpu_time);
#endif

	find_nearest_cluster
		<<< numClusterBlocks, numThreadsPerClusterBlock, clusterBlockSharedDataSize >>>
		(numCoords, numObjs, numClusters,
		 deviceObjects, deviceClusters, deviceMembership, dev_delta_ptr);

	cudaDeviceSynchronize(); checkLastCudaError();

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
	//printf("delta is %f - ", delta);
	loop++; 
	//printf("completed loop %d\n", loop);
	...
} while (delta > threshold && loop < loop_threshold);

/*TODO: Update clusters using dimClusters. Be carefull of layout!!! clusters[numClusters][numCoords] vs dimClusters[numCoords][numClusters] */
for (i = 0; i < numCoords; i++) {
	for (j = 0; j < numClusters; j++) {
		clusters[j*numCoords + i] = dimClusters[i][j];
	}
}

