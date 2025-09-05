
#pragma omp parallel for private(i, j, index) shared(numObjs, delta, newClusterSize, newClusters)
for (i=0; i<numObjs; i++) {
    // find the array index of nearest cluster center 
    index = find_nearest_cluster(numClusters, numCoords, &objects[i*numCoords], clusters);

    // if membership changes, increase delta by 1 
    if (membership[i] != index)
        #pragma omp atomic
        delta += 1.0;

    // assign the membership to object i 
    membership[i] = index;

    // update new cluster centers : sum of objects located within 
    /*
     * TODO: protect update on shared "newClusterSize" array
     */
    #pragma omp atomic 
    newClusterSize[index]++;
    for (j=0; j<numCoords; j++)
        /*
         * TODO: protect update on shared "newClusters" array
         */
        #pragma omp atomic 
        newClusters[index*numCoords + j] += objects[i*numCoords + j];
}
// average the sum and replace old cluster centers with newClusters 
for (i=0; i<numClusters; i++) {
    if (newClusterSize[i] > 0) {
        for (j=0; j<numCoords; j++) {
            clusters[i*numCoords + j] = newClusters[i*numCoords + j] / newClusterSize[i];
        }
    }
}

