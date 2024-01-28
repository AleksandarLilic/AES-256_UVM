# Vector notes

All available vectors are listed under `ref_vectors.json`

> [!NOTE]  
> - `vectors_edge_cases` and `vectors_base` are two test vector that require `-testplusarg ALLOW_VECTOR_CHECKER_NONE` as some plaintexts don't specify ciphertexts  
> - `vectors_NIST_ECBMCT256` (split into two parts) is special case test vector that requires `-testplusarg MCT_VECTORS`. It's different from other vectors as it uses output of the previous encryption (previous CT) as the current input (current PT), in essence chaining operations. There are 1000 such chained operations for a single row in the CSV and a total of 100 rows (so 100,000 operations in the entire test).  


> [!IMPORTANT]   
MCT vectors are split into two parts as single tests crashes Vivado 2023.2. During 91st key Vivado runs out of RAM on a 64GB system w/ Ubuntu 22.04. These two tests should be ran one at a time in order not to run out of memory. One test uses a little over 30GB of RAM, with the OS taking up around 8GB.
