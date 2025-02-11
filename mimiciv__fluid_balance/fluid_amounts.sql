WITH bolus_corrected AS (
  SELECT 
    subject_id,
    hadm_id,
    stay_id,
    CASE 
      WHEN ordercategorydescription='Bolus' THEN amount
      ELSE rate
    END AS rate,
    CASE 
      WHEN ordercategorydescription='Bolus' THEN 'mL/hour'
      ELSE rateuom
    END AS rateuom,
    starttime,
    CASE 
      WHEN ordercategorydescription='Bolus' THEN DATETIME_ADD(starttime,INTERVAL 1 HOUR)
      ELSE endtime
    END AS endtime,
    itemid,
    ordercategoryname
  FROM `physionet-data.mimiciv_icu.inputevents` inputs
  WHERE amountuom='ml'
    AND ordercategoryname != '16-Pre Admission/Non-ICU'),
flattened AS (
  SELECT 
    subject_id,
    hadm_id,
    stay_id,
    starttime AS charttime,
    rate,
    rateuom,
    itemid,
    ordercategoryname
  FROM bolus_corrected
  UNION ALL
  SELECT 
    subject_id,
    hadm_id,
    stay_id,
    endtime AS charttime,
    -1*rate,
    rateuom,
    itemid,
    ordercategoryname
  FROM bolus_corrected),
flattened_adjusted AS (
  SELECT 
    subject_id,
    hadm_id,
    stay_id,
    CASE WHEN ordercategoryname='03-IV Fluid Bolus' THEN 'bolus' ELSE
      CASE WHEN ordercategoryname='01-Drips' THEN 'drips' ELSE
        CASE WHEN ordercategoryname='15-Supplements' THEN 'supplements' ELSE
          CASE WHEN ordercategoryname='07-Blood Products' THEN 'blood_products' ELSE
            CASE WHEN ordercategoryname='12-Parenteral Nutrition' THEN 'parenteral_nutrition' ELSE
              CASE WHEN ordercategoryname='14-Oral/Gastric Intake' THEN 'oral_gastric_intake' ELSE
                CASE WHEN ordercategoryname='04-Fluids (Colloids)' THEN 'colloids' ELSE
                  CASE WHEN ordercategoryname='02-Fluids (Crystalloids)' THEN 'crystalloids' ELSE 'enteral_nutrition'
                  END
                END
              END
            END
          END
        END
      END
    END AS ordercategoryname,
    charttime,
    SUM(rate) AS rate,
    rateuom
  FROM flattened 
  WHERE rate IS NOT NULL
  GROUP BY subject_id,hadm_id,stay_id,charttime,ordercategoryname,rateuom),
pivoted AS (
  SELECT 
    *
  FROM flattened_adjusted
  PIVOT( SUM(rate) FOR ordercategoryname IN ('bolus','drips','supplements','blood_products','parenteral_nutrition','oral_gastric_intake','colloids','crystalloids','enteral_nutrition'))),
rates AS (
  SELECT 
    subject_id,
    hadm_id,
    stay_id,
    charttime AS starttime,
    LEAD(charttime,1) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS endtime,
    SUM(bolus) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS bolus,
    SUM(drips) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS drips,
    SUM(supplements) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS supplements,
    SUM(blood_products) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS blood_products,
    SUM(parenteral_nutrition) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS parenteral_nutrition,
    SUM(oral_gastric_intake) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS oral_gastric_intake,
    SUM(colloids) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS colloids,
    SUM(crystalloids) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS crystalloids,
    SUM(enteral_nutrition) OVER(PARTITION BY subject_id, hadm_id, stay_id ORDER BY charttime) AS enteral_nutrition
  FROM pivoted)
SELECT 
  subject_id,
  hadm_id,
  stay_id,
  starttime,
  endtime,
  COALESCE(blood_products,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS blood_products,
  COALESCE(bolus,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS bolus,
  COALESCE(colloids,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS colloids,
  COALESCE(crystalloids,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS crystalloids,
  COALESCE(drips,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS drips,
  COALESCE(enteral_nutrition,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS enteral_nutrition,
  COALESCE(oral_gastric_intake,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS oral_gastric_intake,
  COALESCE(parenteral_nutrition,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS parenteral_nutrition,
  COALESCE(supplements,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS supplements,
  COALESCE(blood_products,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(bolus,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(colloids,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(crystalloids,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(drips,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(enteral_nutrition,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(oral_gastric_intake,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(parenteral_nutrition,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60)+
    COALESCE(supplements,0)*(DATETIME_DIFF(endtime,starttime,MINUTE)/60) AS total_amount
  FROM rates
