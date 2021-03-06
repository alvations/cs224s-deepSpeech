DATE=`ls -t ../../out/ | head -n 1`
LASTDATE=`ls -t ../../out/ | head -n 2 | sed -n 2p`
SAVEBASE=experiments/${DATE}-$1
mkdir -p $SAVEBASE

cp -r ../../out/${LASTDATE}/calibration $SAVEBASE/calibration  # comment in $1

cp -r application.conf $SAVEBASE/configuration.conf
cp -r evaluation.conf $SAVEBASE/

# save weights
psql -d $DBNAME -c "select * 
from dd_inference_result_variables_mapped_weights 
order by weight desc" > experiments/${DATE}-$1/weights.txt

export EVAL_BASE=speech-data/output/
# save evaluation results
mkdir -p $SAVEBASE/evaluation
cp -r $EVAL_BASE/* $SAVEBASE/evaluation/ 

echo "Experiment result saved to: experiments/${DATE}-$1/"
