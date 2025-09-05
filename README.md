# Parallel Processing Systems — Lab Exercises

This project contains five exercises exploring parallel programming with **OpenMP**, **locks**, **CUDA**, and **MPI**. Each exercise demonstrates different approaches and scalability trade-offs.

---

## Exercise 1 — OpenMP: Game of Life
Parallel Conway’s Game of Life with OpenMP.  
- Shows how problem size affects scalability.  
- Small grids → overhead dominates.  
- Medium grids → near-linear speedup.  
- Large grids → memory/bus contention limits scaling.

---

## Exercise 2 — OpenMP: K-means & Floyd–Warshall
**K-means**:  
- Naive shared accumulators are slower than serial.  
- Copy-reduce with padding and first-touch yields near-linear speedup.  

**Floyd–Warshall**:  
- Recursive version exposes little parallelism.  
- Tiled version achieves much better scaling via cache locality.

---

## Exercise 3 — Locks & Concurrent Lists
**Locks**:  
- Mutex/Spin degrade at scale.  
- TAS/TTAS add bus traffic.  
- Array/CLH locks scale best.  

**Lists**:  
- Coarse/fine locking limits throughput.  
- Optimistic and Lazy perform better; reads don’t lock in Lazy.  
- Non-blocking version scales best under contention.

---

## Exercise 4 — CUDA: K-means
GPU implementations of K-means.  
- Naive baseline, Transpose (coalesced access), Shared memory, and All-GPU.  
- Performance mainly depends on memory access patterns.  
- All-GPU version removes CPU bottlenecks for best results.

---

## Exercise 5 — MPI: K-means & Jacobi
**K-means**: Uses per-rank reductions with `MPI_Allreduce`; scales nearly ideally.  
**Jacobi 2D**: Heat diffusion with halo exchange.  
- Small grids scale well, larger ones limited by communication.  
- Convergence checking adds significant overhead.

---

## Key Takeaways
- Aggregate locally, then reduce globally for scalability.  
- Memory locality (tiling, padding, coalescing) is crucial.  
- Scalable locks or lock-free designs outperform naive locks.  
- Full GPU offload removes CPU bottlenecks.  
- MPI performance depends on balancing compute with communication.
