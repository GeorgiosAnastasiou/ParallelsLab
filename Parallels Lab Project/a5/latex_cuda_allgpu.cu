__global__ static
void find_nearest_cluster(int numCoords,
        int numObjs,
        int numClusters,
        double *deviceobjects,           //  [numCoords][numObjs]
        /*                          
                                    TODO: If you choose to do (some of) the new centroid calculation here, you will need some extra parameters here (from "update_centroids").
         */                          
        int *devicenewClusterSize,           //  [numClusters]
        double *devicenewClusters,    //  [numCoords][numClusters]
                                      //added above two
        double *deviceClusters,    //  [numCoords][numClusters]
        int *deviceMembership,          //  [numObjs]
        double *devdelta)
{
    extern __shared__ double shmemClusters[];

    /* TODO: copy me from shared version... */
    . . . 
    /* TODO: additional steps for calculating new centroids in GPU? */
    atomicAdd(&devicenewClusterSize[index], 1);
    for (i = 0; i < numCoords; ++i)
        atomicAdd(&devicenewClusters[i*numClusters + index], deviceobjects[i*numObjs + tid]);
}

    __global__ static
void update_centroids(int numCoords,
        int numClusters,
        int *devicenewClusterSize,           //  [numClusters]
        double *devicenewClusters,    //  [numCoords][numClusters]
        double *deviceClusters)    //  [numCoords][numClusters])
{

    /* TODO: additional steps for calculating new centroids in GPU? */
    //was empty
    const int tid = get_tid();
    if (tid >= numClusters*numCoords) return;
    int cluster = tid % numClusters; // tid = coord*numClusters + cluster, which makes access bellow fast af
    if (devicenewClusterSize[cluster] > 0)
        deviceClusters[tid] = devicenewClusters[tid]/devicenewClusterSize[cluster];
    devicenewClusters[tid] = 0.0;
    // apparently synchronizing here doesn't change the results (also each thread does it lol, could add if (coord == 0))
    devicenewClusterSize[cluster] = 0;
}
