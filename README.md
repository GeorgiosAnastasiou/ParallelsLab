# Parallel Processing Systems — Lab Exercises

This project contains five exercises exploring parallel programming with **OpenMP**, **locks**, **CUDA**, and **MPI**.

---

## Exercise 1 — OpenMP: Game of Life
Implemented Conway’s Game of Life with OpenMP, parallelizing the main loop and automating execution with scripts.

---

## Exercise 2 — OpenMP: K-means & Floyd–Warshall
Parallelized the K-means clustering algorithm with different synchronization strategies (naive shared, copy-reduce, padding, first-touch).  
Implemented Floyd–Warshall both recursively and with tiling to study parallelism and locality.

---

## Exercise 3 — Locks & Concurrent Lists
Implemented and benchmarked multiple locking mechanisms (mutex, spin, TAS, TTAS, Array, CLH).  
Built concurrent linked list variants using coarse-grain, fine-grain, optimistic, lazy, and non-blocking synchronization.

---

## Exercise 4 — CUDA: K-means
Developed GPU kernels for K-means: naive, transpose-based, shared-memory optimized, and a full All-GPU version.

---

## Exercise 5 — MPI: K-means & Jacobi
Implemented distributed-memory K-means using MPI with collective reductions.  
Implemented 2D Jacobi heat diffusion with domain decomposition and halo exchange.
