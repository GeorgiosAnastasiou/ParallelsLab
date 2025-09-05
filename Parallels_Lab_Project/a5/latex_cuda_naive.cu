__device__ int get_tid(){
	return blockIdx.x * blockDim.x + threadIdx.x; /* TODO: copy me from naive version... */
}

/* square of Euclid distance between two multi-dimensional points */
__host__ __device__ inline static
double euclid_dist_2(int    numCoords,
                    int    numObjs,
                    int    numClusters,
                    double *objects,     // [numObjs][numCoords]
                    double *clusters,    // [numClusters][numCoords]
                    int    objectId,
                    int    clusterId)
{
    int i;
    double ans=0.0;

	/* TODO: Calculate the euclid_dist of elem=objectId of objects from elem=clusterId from clusters*/
    // was empty
    for (i=0; i<numCoords; i++)
        ans += (objects[objectId*numCoords + i] - clusters[clusterId*numCoords + i]) *
               (objects[objectId*numCoords + i] - clusters[clusterId*numCoords + i]);

    return(ans);
}

__global__ static
void find_nearest_cluster(int numCoords,
                          int numObjs,
                          int numClusters,
                          double *objects,           //  [numObjs][numCoords]
                          double *deviceClusters,    //  [numClusters][numCoords]
                          int *deviceMembership,          //  [numObjs]
                          double *devdelta)
{

	/* Get the global ID of the thread. */
    int tid = get_tid(); 

	/* TODO: Maybe something is missing here... should all threads run this? */
    if (tid < numObjs) { // was 1
        int   index, i;
        double dist, min_dist;

        /* find the cluster id that has min distance to object */
        index = 0;
        /* TODO: call min_dist = euclid_dist_2(...) with correct objectId/clusterId */
        min_dist = euclid_dist_2(numCoords, numObjs, numClusters, objects, deviceClusters, tid, 0); // was empty

        for (i=1; i<numClusters; i++) {
            /* TODO: call dist = euclid_dist_2(...) with correct objectId/clusterId */
            dist = euclid_dist_2(numCoords, numObjs, numClusters, objects, deviceClusters, tid, i); // was empty
 
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


    const unsigned int numThreadsPerClusterBlock = (numObjs > blockSize)? blockSize: numObjs;
    /* TODO: Calculate Grid size, e.g. number of blocks. */
    const unsigned int numClusterBlocks = (numObjs + numThreadsPerClusterBlock - 1) / numThreadsPerClusterBlock; // was -1
    const unsigned int clusterBlockSharedDataSize = 0;


    do {
        timing_internal = wtime(); 
 
		/* GPU part: calculate new memberships */
        #ifdef TIMER_ANALYSIS
        time_start = wtime();
        #endif
		        
        /* TODO: Copy clusters to deviceClusters
        checkCuda(cudaMemcpy(...)); */
        checkCuda(cudaMemcpy(deviceClusters, clusters,
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
                newClusters[index][j] += objects[i*numCoords + j];
        }
        
        /* average the sum and replace old cluster centers with newClusters */
        for (i=0; i<numClusters; i++) {
            for (j=0; j<numCoords; j++) {
                if (newClusterSize[i] > 0)
                    clusters[i*numCoords + j] = newClusters[i][j] / newClusterSize[i];
                newClusters[i][j] = 0.0;   /* set back to 0 */
            }
            newClusterSize[i] = 0;   /* set back to 0 */
        }

        delta /= numObjs;
       	//printf("delta is %f - ", delta);
        loop++; 
        ...     
    } while (delta > threshold && loop < loop_threshold);
    
