TODO
====

- Train on full dataset haven't succeeded yet...
- GET RT03 DONE!!
- would removing "lattices" table boost the speed?

New features 2:
- Coreference
- dependency?

Run on a larger dataset
- try different feature combs

    New features:
X   - ngram skip silence
X   - chaining??

- RERUN supervision: wrong order in I!
- Error analysis
- Optimize for PRECISION rather than recall
- A- / TH- / 

- Obtain Google 3/4/5gram

- distant supervision?

X regenerate candidates with cand_words (have to)
X OR rewrite cand_match.py

Links

- A.ends + 1 = B.starts  => "AB" ngram


f_cand_2gram: 114920536

e.g.

    deepspeech=# select * from f_cand_2gram limit 80;
                 lattice_id              | candidate_id |   ngram
    -------------------------------------+--------------+------------
     19960510aCNN_EPN#Byron_Miranda@0008 |        18917 | <s> IT'S
     19960510aCNN_EPN#Byron_Miranda@0008 |        18920 | <s> IT'S
     19960510aCNN_EPN#Byron_Miranda@0008 |        18917 | <s> TIME
     19960510aCNN_EPN#Byron_Miranda@0008 |        18921 | <s> TIME
     19960510aCNN_EPN#Byron_Miranda@0008 |        18917 | <s> TIME
     19960510aCNN_EPN#Byron_Miranda@0008 |        18922 | <s> TIME
     19960510aCNN_EPN#Byron_Miranda@0008 |        18918 | <s> I'M
     19960510aCNN_EPN#Byron_Miranda@0008 |        18923 | <s> I'M
     19960510aCNN_EPN#Byron_Miranda@0008 |        18918 | <s> TIME
     19960510aCNN_EPN#Byron_Miranda@0008 |        18924 | <s> TIME
     19960510aCNN_EPN#Byron_Miranda@0008 |        18918 | <s> TIME
     19960510aCNN_EPN#Byron_Miranda@0008 |        18926 | <s> TIME


# Examine 2gram 
    select array_agg(c.word order by c.candidate_id), min(c.candidate_id) as cid, min(ngram)
    from f_cand_2gram f, candidate c
     where c.lattice_id = f.lattice_id 
     and c.candidate_id = f.candidate_id
     group by c.lattice_id
     limit 10;

    select c.*, ngram
    from f_cand_2gram f, candidate c
     where c.lattice_id = f.lattice_id 
     and c.candidate_id = f.candidate_id
     limit 10;

# TODO Story

1. beat the crap
2. near real time


## ERRORs

20001101_1400_1430_CNN_HDL034@0006: 

    deepspeech=# select * from transcript_array where lattice_id ='20001101_1400_1430_CNN_HDL034@0006';
                 lattice_id             |     words
    ------------------------------------+----------------
     20001101_1400_1430_CNN_HDL034@0006 | {<s>,THE,</s>}
    (1 row)