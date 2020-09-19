C     NICHEMAPR: SOFTWARE FOR BIOPHYSICAL MECHANISTIC NICHE MODELLING

C     COPYRIGHT (C) 2020 MICHAEL R. KEARNEY AND WARREN P. PORTER

C     THIS PROGRAM IS FREE SOFTWARE: YOU CAN REDISTRIBUTE IT AND/OR MODIFY
C     IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY
C     THE FREE SOFTWARE FOUNDATION, EITHER VERSION 3 OF THE LICENSE, OR (AT
C      YOUR OPTION) ANY LATER VERSION.

C     THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT
C     WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
C     MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU
C     GENERAL PUBLIC LICENSE FOR MORE DETAILS.

C     YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE
C     ALONG WITH THIS PROGRAM. IF NOT, SEE HTTP://WWW.GNU.ORG/LICENSES/.

C	  THIS SUBROUTINE SIMULTANEOUSLY SOLVES FOR THE SKIN AND FUR/AIR 
C     INTERFACE TEMPERATURE THAT BALANCES THE HEAT BUDGET FOR A NON-
C     RESPIRING BODY PART, ACCOUNTING FOR DORSAL AND VENTRAL DIFFERENCES
C     AND EVAPOURATION FROM THE SKIN. IT IS THE CORE OF THE ENDOTHERM
C     MODEL

C     FURTST = TEST FOR FUR PRESENCE (ZERO IF NO FUR)

C     TA = AIR TEMPERATURE (C)
C     TCONDSB = SUBSTRATE TEMPERATURE FOR CONDUCTION (MIGHT BE DIFF FROM IR FROM DIGGING A DEPRESSION)
C     D = CHARACTERISTIC DIMENSION FOR CONVECTION
C     CONVAR = AREA FOR CONVECTION, INCLUDING FUR (M2)
C     CONVSK = AREA OF SKIN FOR EVAPORATION BY SWEATING (M2)
C     FLTYPE = FLUID TYPE: 0 = AIR; 1 = FRESH WATER; 2 = SALT WATER

      SUBROUTINE SIMULSOL(DIFTOL,IPT,FURVARS,GEOMVARS,ENVVARS,TRAITS,
     & TFA,SKINW,TSKIN,RESULTS)

      IMPLICIT NONE
      
      DOUBLE PRECISION AK1,AK2,ALT,ASEMAJ,ASQG,BETARA,BG,BL,BP,BR,BS
      DOUBLE PRECISION BSEMIN,BSQG,CD,CF,CONVAR,CONVRES,CONVSK,CSEMIN
      DOUBLE PRECISION CSQG,D,DIFTOL,DV1,DV2,DV3,DV3T1,DV3T2,DV3T3,DV4
      DOUBLE PRECISION DV5,EMIS,ENVVARS,FABUSH,FAGRD,FASKY,FATTHK,FAVEG
      DOUBLE PRECISION FLSHASEMAJ,FLSHBSEMIN,FLSHCSEMIN,FLTYPE,FLYHR
      DOUBLE PRECISION FURTHRMK,FURTST,FURVARS,FURWET,GEOMVARS,HC,HD
      DOUBLE PRECISION HDFREE,IPT,KEFF,KFUR,KRAD,LEN,NTRY,PCTBAREVAP
      DOUBLE PRECISION PCTEYES,PI,QCOND,QCONV,QENV,QFSEVAP,QGENNET,QR1
      DOUBLE PRECISION QR2,QR3,QR4,QRAD,QRBSH,QRGRD,QRSKY,QRVEG,QSEVAP
      DOUBLE PRECISION QSLR,RESULTS,RFLESH,RFUR,RH,RRAD,RSKIN,SEVAPRES
      DOUBLE PRECISION SHAPE,SIG,SKINW,SOLCT,SOLPRO,SSQG,SUBQFAT,SUCCESS
      DOUBLE PRECISION SURFAR,TA,TBUSH,TC,TCONDSB,TFA,TFACALC,TFADIFF
      DOUBLE PRECISION TFAT1,TFAT2,TFAT3,TFAT4,TLOWER,TR,TRAITS,TRAPPX
      DOUBLE PRECISION TS,TS2T1,TS2T2,TSKCALC,TSKCALC1,TSKCALC2
      DOUBLE PRECISION TSKCALCAV,TSKDIFF,TSKIN,TSKT1,TSKT2,TSKT3,TSKY
      DOUBLE PRECISION TVEG,VEL,VOL,XR,ZFUR,ZL
     
      INTEGER I
     
      DIMENSION CONVRES(15),SEVAPRES(7),RESULTS(15),BETARA(3)
      DIMENSION FURVARS(9) ! LEN,ZFUR,FURTHRMK,KEFF,BETARA,FURTST, ! NOTE KEFF DEPENDS ON IF SOLAR, AND THEN WHAT SIDE, SET IN R
      DIMENSION GEOMVARS(16) ! SHAPE,SUBQFAT,SURFAR,VOL,D,CONVAR,CONVSK,RFUR,RFLESH,RSKIN,XR,RRAD,ASEMAJ,BSEMIN,CSEMIN,CD,
      DIMENSION ENVVARS(17) ! FLTYPE,TA,TS,TBUSH,TVEG,TLOWER,TSKY,TCONDSB,RH,VEL,BP,ALT,FASKY,FABUSH,FAVEG,FAGRD,QSLR
      DIMENSION TRAITS(9) !TC,AK1,AK2,EMIS,FATTHK,FLYHR,FURWET,PCTBAREVAP,PCTEYES

C     CONSTANTS      
      SIG = 5.6697E-8 ! W M-2 K-4
      PI = ACOS(-1.0D0)
      
C     UNPACKING VARIABLES

      LEN=FURVARS(1)
      ZFUR=FURVARS(2)
      FURTHRMK=FURVARS(3)
      KEFF=FURVARS(4)
      BETARA=FURVARS(5:7)
      FURTST=FURVARS(8)
      ZL=FURVARS(9)
      
      SHAPE=GEOMVARS(1)
      SUBQFAT=GEOMVARS(2)
      SURFAR=GEOMVARS(3)
      VOL=GEOMVARS(4)
      D=GEOMVARS(5)
      CONVAR=GEOMVARS(6)
      CONVSK=GEOMVARS(7)
      RFUR=GEOMVARS(8)
      RFLESH=GEOMVARS(9)
      RSKIN=GEOMVARS(10)
      XR=GEOMVARS(11)
      RRAD=GEOMVARS(12)
      ASEMAJ=GEOMVARS(13)
      BSEMIN=GEOMVARS(14)
      CSEMIN=GEOMVARS(15)
      CD=GEOMVARS(16)
      
      FLTYPE=ENVVARS(1)
      TA=ENVVARS(2)
      TS=ENVVARS(3)
      TBUSH=ENVVARS(4)
      TVEG=ENVVARS(5)
      TLOWER=ENVVARS(6)
      TSKY=ENVVARS(7)
      TCONDSB=ENVVARS(8)
      RH=ENVVARS(9)
      VEL=ENVVARS(10)
      BP=ENVVARS(11)
      ALT=ENVVARS(12)
      FASKY=ENVVARS(13)
      FABUSH=ENVVARS(14)
      FAVEG=ENVVARS(15)
      FAGRD=ENVVARS(16)
      QSLR=ENVVARS(17)
      
      TC=TRAITS(1)
      AK1=TRAITS(2)
      AK2=TRAITS(3)
      EMIS=TRAITS(4)
      FATTHK=TRAITS(5)
      FLYHR=TRAITS(6)
      FURWET=TRAITS(7)
      PCTBAREVAP=TRAITS(8)
      PCTEYES=TRAITS(9)
      
C     INITIALISE
      SOLPRO=1.
      SOLCT=0.
      NTRY=0.
      SUCCESS=1.
      
      IF(FURTST .GT. 0.0000000) THEN
       GO TO 5
      ELSE
       GO TO 120
      ENDIF
      
****************************************************************************************************************
C     BEGIN CALCULATING TSKIN AND TFA VALUES FOR FURRED BODY PARTS
****************************************************************************************************************
5     CONTINUE
      NTRY = NTRY + 1       
      DO 105, I=1,20
11     CONTINUE
       CALL CONV_ENDO(TS,TA,SHAPE,SURFAR,FLTYPE,FURTST,D,TFA,VEL,ZFUR,
     &  BP,ALT,CONVRES)
       HC=CONVRES(2)
       HD=CONVRES(5)
       HDFREE=CONVRES(6)
       CALL SEVAP_ENDO(BP,TA,RH,VEL,TC,TSKIN,ALT,SKINW,
     & FLYHR,CONVSK,HD,HDFREE,PCTBAREVAP,PCTEYES,ZFUR,FURWET,
     & TFA, CONVAR, SEVAPRES)
       QSEVAP = SEVAPRES(1)
       QFSEVAP = SEVAPRES(7) 

       IF(FURTHRMK.GT.0.)THEN
C       USER SUPPLIED FUR THERMAL CONDUCTIVITY VALUE
        KFUR = FURTHRMK
       ELSE
C       NEED A TRAD APPROXIMATION FOR CALCULATING KRAD.
        TRAPPX = (TSKIN*(1-XR))+(TFA*XR)
        KRAD = (16.0*SIG*(TRAPPX+273.15)**3.)/(3.*BETARA(1)) ! EQ7 IN CONLEY AND PORTER 1986
        KFUR = KEFF+KRAD
       ENDIF
        
       IF(IPT.EQ.1)THEN ! CYLINDER GEOMETRY
        CF=(2.*PI*KFUR*LEN)/(DLOG(RFUR/RSKIN))
        DV1=1.+((CF*RFLESH**2.)/(4.*AK1*VOL))+
     &   ((CF*RFLESH**2.)/(2.*AK2*VOL))*DLOG(RSKIN/RFLESH)
        DV2=((QSEVAP*RFLESH**2.)/(4.*AK1*VOL))+
     &   ((QSEVAP*RFLESH**2.)/(2*AK2*VOL))*DLOG(RSKIN/RFLESH)
        DV3=((((CF/DV1)*(TC-DV2-TFA))*RFLESH**2.)/(2.*KFUR*VOL))
     &   *LOG(RFUR/RRAD)
        DV4 = (CD*CF*RFLESH**2.)/(DV1*4.*AK1*VOL)
        DV5 = ((CD*CF*RFLESH**2.)/(DV1*2.*AK2*VOL))*DLOG(RSKIN/RFLESH)
       ENDIF
       
       IF(IPT.EQ.2)THEN ! SPHERE GEOMETRY
        CF=(4.*PI*KFUR*RSKIN*RFUR)/(RFUR-RSKIN)
        DV1=1.+((CF*RFLESH**2.)/(6.*AK1*VOL))+
     &   ((CF*RFLESH**3.)/(3*AK2*VOL))*((RSKIN-RFLESH)/(RSKIN*RFLESH))
        DV2=((QSEVAP*RFLESH**2.)/(6.*AK1*VOL))+
     &   ((QSEVAP*RFLESH**3.)/(3.*AK2*VOL))*
     &   ((RSKIN-RFLESH)/(RSKIN*RFLESH))
        DV3=((((CF/DV1)*(TC-DV2-TFA))*RFLESH**3.)/(3.*KFUR*VOL))
     &   *((1./RRAD)-(1/RFUR))
        DV4 = (CD*CF*RFLESH**2.)/(DV1*6.*AK1*VOL)
        DV5 = ((CD*CF*RFLESH**3.)/(DV1*3.*AK2*VOL))*
     &   ((RSKIN-RFLESH)/(RFLESH*RSKIN))
       ENDIF
       
       IF(IPT.GE.3)THEN ! ELLIPSOID GEOMETRY
        FLSHASEMAJ=ASEMAJ-FATTHK
        FLSHBSEMIN=BSEMIN-FATTHK
        FLSHCSEMIN=CSEMIN-FATTHK
        IF((SUBQFAT.EQ.1.).AND.(FATTHK.GT.0.00))THEN
         ASQG = FLSHASEMAJ**2.
         BSQG = FLSHBSEMIN**2.
         CSQG = FLSHCSEMIN**2.
        ELSE
         ASQG = ASEMAJ**2.
         BSQG = BSEMIN**2.
         CSQG = CSEMIN**2.
        ENDIF
        SSQG = (ASQG*BSQG*CSQG)/(ASQG*BSQG+ASQG*CSQG+BSQG*CSQG)
C       GETTING THE RADIUS IN THE "B" DIRECTION AT THE FLESH:
        IF((SUBQFAT.EQ.1.).AND.(FATTHK.GT.0.00))THEN
         BG=FLSHBSEMIN
        ELSE
         BG=BSEMIN
        ENDIF
C       GETTING THE RADIUS IN THE "B" DIRECTION AT THE SKIN. WHEN THERE'S NO SUBQ FAT, BG=BS.
        BS = BSEMIN
C       GETTING THE RADIUS IN THE "B" DIRECTION AT THE FUR-AIR INTERFACE:
        BL=BSEMIN+ZL
        BR=BS+(XR*ZL)
        CF=(3.*KFUR*VOL*(BL*BS))/((((3*SSQG)**0.5)**3.)*(BL-BS))
        DV1=1.+((CF*SSQG)/(2.*AK1*VOL))+
     &   ((CF*((3.*SSQG)**0.5)**3.)/(3.*AK2*VOL))*
     &   ((BS-BG)/(BS*BG))
        DV2=((QSEVAP*SSQG)/(2*AK1*VOL))+
     &   ((QSEVAP*((3.*SSQG)**0.5)**3.)/(3.*AK2*VOL))*
     &   ((BS-BG)/(BS*BG))
        DV3T1=(CF/DV1)*(TC-DV2-TFA)
        DV3T2=(((3.*SSQG)**0.5)**3.0)
        DV3T3=(BL-BR)/(BR*BL)
        DV3=((DV3T1*DV3T2)/(3.*KFUR*VOL))*DV3T3
        DV4 = (CD*CF*SSQG)/(DV1*2.*AK1*VOL)
        DV5 = ((CD*CF*(SQRT(3*SSQG))**3.)/(DV1*3.*AK2*VOL))*
     &  ((BS-BG)/(BG*BS))
       ENDIF

       TR = (DV3+TFA)+273.15
       
C      THESE QR VARIABLES INCORPORATE THE VARIOUS HR VALUES FOR RADIANT EXCHANGE WITH SKY, GROUND, ETC.
       QR1=CONVAR*(FASKY*4.*EMIS*SIG*(TR)**3.)
       QR2=CONVAR*(FABUSH*4.*EMIS*SIG*(TR)**3.)
       QR3=CONVAR*(FAVEG*4.*EMIS*SIG*(TR)**3.)
       QR4=CONVAR*(FAGRD*4.*EMIS*SIG*(TR)**3.)

       TFAT1=QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER-
     &  DV3*(QR1+QR2+QR3+QR4)+(HC*CONVAR*TA)

C      INCLUDES TERM  (QFSEVAP) FOR HEAT LOST DUE TO EVAPORATION FROM THE FUR SURFACE TO 
C      CALCULATIONS OF TFA (E.G. WET FUR FROM RAIN)
       IF(IPT.EQ.1.)THEN ! CYLINDER GEOMETRY
        TFAT2=((CD*QSEVAP*RFLESH**2.)/(4.*AK1*VOL))+
     &   (((CD*QSEVAP*RFLESH**2.)/(2.*AK2*VOL))*LOG(RSKIN/RFLESH))+QSLR
     &  - QFSEVAP
       ENDIF

       IF(IPT.EQ.2.)THEN ! SPHERE GEOMETRY
        TFAT2=((CD*QSEVAP*RFLESH**2.)/(6.*AK1*VOL))+
     &   (((CD*QSEVAP*RFLESH**3.)/(3.*AK2*VOL))*
     &   ((RSKIN-RFLESH)/(RFLESH*RSKIN)))+QSLR - QFSEVAP
       ENDIF

       IF(IPT.GE.3.)THEN ! ELLIPSOID GEOMETRY
        TFAT2=((CD*QSEVAP*SSQG)/(2.*AK1*VOL))+
     &   (((CD*QSEVAP*(SQRT(3.*SSQG))**3.)/(3.*AK2*VOL))*
     &   ((BS-BG)/(BG*BS)))+QSLR-QFSEVAP
       ENDIF

       TFAT3=CD*TCONDSB+TC*((CF/DV1)-CD+DV4+DV5)-
     &   DV2*(DV4+DV5+(CF/DV1))
       TFAT4=(QR1+QR2+QR3+QR4)+(HC*CONVAR)+(DV4+DV5)+(CF/DV1)

       TFACALC = (TFAT1+TFAT2+TFAT3)/TFAT4
       
       QRSKY=QR1*((DV3+TFACALC)-TSKY)
       QRBSH=QR2*((DV3+TFACALC)-TBUSH)
       QRVEG=QR3*((DV3+TFACALC)-TVEG)
       QRGRD=QR4*((DV3+TFACALC)-TLOWER)
       QRAD = QRSKY+QRBSH+QRVEG+QRGRD
       QCONV = HC*CONVAR*(TFACALC-TA)

       IF(IPT.EQ.1)THEN ! CYLINDER GEOMETRY
        QCOND = TC*(CD-DV4-DV5)+DV2*(DV4+DV5)+TFACALC*(DV4+DV5)-
     &   ((CD*QSEVAP*RFLESH**2.)/(4.*AK1*VOL))-
     &   (((CD*QSEVAP*RFLESH**2.)/(2.*AK1*VOL))*LOG(RSKIN/RFLESH))-
     &   CD*TCONDSB
       ENDIF

       IF(IPT.EQ.2)THEN ! SPHERE GEOMETRY
        QCOND = TC*(CD-DV4-DV5)+DV2*(DV4+DV5)+TFACALC*(DV4+DV5)-
     &   ((CD*QSEVAP*RFLESH**2.)/(6.*AK1*VOL))-
     &   (((CD*QSEVAP*RFLESH**3.)/(3.*AK1*VOL))*
     &   ((RSKIN-RFLESH)/(RFLESH*RSKIN)))-CD*TCONDSB
       ENDIF

       IF(IPT.GE.3)THEN ! ELLIPSOID GEOMETRY
        QCOND = TC*(CD-DV4-DV5)+DV2*(DV4+DV5)+TFACALC*(DV4+DV5)-
     &  ((CD*QSEVAP*SSQG)/(2.*AK1*VOL))-
     &  (((CD*QSEVAP*(SQRT(3.*SSQG))**3.)/(3.*AK1*VOL))*
     &  ((BS-BG)/(BG*BS)))-CD*TCONDSB
       ENDIF

       QENV = QRAD+QCONV+QCOND+QFSEVAP-QSLR

       IF(IPT.EQ.1.)THEN ! CYLINDER GEOMETRY
        TSKCALC1 = TC-(((QENV+QSEVAP)*RFLESH**2.)/(4.*AK1*VOL))-
     &   (((QENV+QSEVAP)*RFLESH**2.)/(2.*AK2*VOL))*LOG(RSKIN/RFLESH)
        TSKCALC2 = ((QENV*RFLESH**2.)/(2.*KFUR*VOL))*LOG(RFUR/RSKIN)+
     &   TFACALC
       ENDIF

       IF(IPT.EQ.2.)THEN ! SPHERE GEOMETRY
        TSKCALC1 = TC-(((QENV+QSEVAP)*RFLESH**2.)/(6.*AK1*VOL))-
     &   (((QENV+QSEVAP)*RFLESH**3.)/(3.*AK2*VOL))*
     &   ((RSKIN-RFLESH)/(RFLESH*RSKIN))
        TSKCALC2 = ((QENV*RFLESH**3.)/(3.*KFUR*VOL))*
     &   ((RFUR-RSKIN)/(RFUR*RSKIN))+TFACALC
       ENDIF    

       IF(IPT.GE.3.)THEN ! ELLIPSOID GEOMETRY
        TSKCALC1 = TC-(((QENV+QSEVAP)*SSQG)/(2.*AK1*VOL))-
     &  (((QENV+QSEVAP)*((3.*SSQG)**0.5)**3.)/(3.*AK2*VOL))*
     &  ((BS-BG)/(BS*BG))
        TS2T1=(QENV*((3.*SSQG)**0.5)**3.)/(3.*KFUR*VOL)
        TS2T2=(BL-BS)/(BS*BL)
        TSKCALC2 = (TS2T1*TS2T2)+TFACALC
       ENDIF

       TSKCALCAV = (TSKCALC1+TSKCALC2)/2.

       TFADIFF = ABS(TFA-TFACALC)
       TSKDIFF = ABS(TSKIN-TSKCALCAV)

C      CHECK TO SEE IF THE TFA GUESS AND THE CALCULATED GUESS ARE SIMILAR
       IF(TFADIFF.LT.DIFTOL)THEN
C       IF YES, MOVE ON TO CHECK THE TFA GUESS AND CALCULATION
        GO TO 16
       ENDIF
C      IF NO, TRY ANOTHER INITIAL TFA GUESS
       IF(SOLPRO.EQ.1.)THEN
C       FIRST SOLUTION PROCEDURE IS TO SET TFA GUESS TO THE CALCULATED TFA
        TFA=TFACALC
       ELSE
        IF(SOLPRO.EQ.2.)THEN
C        SECOND SOLUTION PROCEDURE IS TO SET TFA GUESS TO AVERAGE OF PREVIOUS GUESS
C        AND CALCULATED TFA
         TFA=(TFACALC+TFA)/2.
        ELSE
C        FINAL SOLUTION PROCEDURE IS TO INCREASE TFA GUESS INCREMENTALLY TO AVOID
C        LARGE JUMPS PARTICULARLY WHEN DEALING WITH EVAPORATION AT HIGH TEMPERATURES.
         IF((TFA-TFACALC).LT.0.)THEN
          IF(TFADIFF.GT.3.5)THEN
           TFA = TFA+0.5
          ENDIF
          IF((TFADIFF.GT.1.0).AND.(TFADIFF.LT.3.5))THEN
           TFA = TFA+0.05
          ENDIF
          IF((TFADIFF.GT.0.1).AND.(TFADIFF.LT.1.0))THEN
           TFA = TFA+0.05
          ENDIF
          IF((TFADIFF.GT.0.01).AND.(TFADIFF.LT.0.1))THEN
           TFA = TFA+0.005
          ENDIF
          IF((TFADIFF.GT.0.0).AND.(TFADIFF.LT.0.01))THEN
           TFA=TFA+0.0001
          ENDIF
          IF((TFADIFF.GT.0.0).AND.(TFADIFF.LT.0.001))THEN
           TFA=TFA+0.00001
          ENDIF
         ELSE
          IF(TFADIFF.GT.3.5)THEN
           TFA = TFA-0.5
          ENDIF
          IF((TFADIFF.GT.1.0).AND.(TFADIFF.LT.3.5))THEN
           TFA = TFA-0.05
          ENDIF
          IF((TFADIFF.GT.0.1).AND.(TFADIFF.LT.1.0))THEN
           TFA = TFA-0.05
          ENDIF
          IF((TFADIFF.GT.0.01).AND.(TFADIFF.LT.0.1))THEN
           TFA = TFA-0.005
          ENDIF
          IF((TFADIFF.GT.0.001).AND.(TFADIFF.LT.0.01))THEN
           TFA=TFA-0.0001
          ENDIF
          IF((TFADIFF.GT.0.0).AND.(TFADIFF.LT.0.001))THEN
           TFA=TFA-0.00001
          ENDIF
         ENDIF
        ENDIF
       ENDIF
       TSKIN=TSKCALCAV
       SOLCT=SOLCT+1.

       IF(SOLCT.GE.100.)THEN
        IF(SOLPRO.NE.3.0)THEN
         SOLCT=0.
         SOLPRO=SOLPRO+1
        ELSE
C        EVEN THE SECOND WAY OF SOLVING FOR BALANCE DOESN'T WORK, INCREASE TOLERANCE
         IF(DIFTOL.EQ.0.001)THEN
          DIFTOL=0.01
          SOLCT=0.
          SOLPRO=1.
         ELSE
          SUCCESS=0.
          QGENNET=0.
          GOTO 150
         ENDIF
        ENDIF
       ENDIF
       GO TO 11
       
C      CHECK TO SEE IF THE TSK GUESS AND CALCULATION ARE SIMILAR
16     IF(TSKDIFF.LT.DIFTOL)THEN
C       IF YES, BOTH TFA AND TSK GUESSES ARE SIMILAR TO THE CALCULATED VALUES

        IF(IPT.EQ.1.)THEN ! CYLINDER GEOMETRY
         QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(4.*AK1*VOL))+
     &   ((RFLESH**2./(2.*AK2*VOL))*LOG(RSKIN/RFLESH)))
        ENDIF

        IF(IPT.EQ.2.)THEN ! SPHERE GEOMETRY
         QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(6.*AK1*VOL))+
     &    ((RFLESH**3./(3.*AK2*VOL))*((RSKIN-RFLESH)/(RFLESH*RSKIN))))
        ENDIF

        IF(IPT.GE.3.)THEN ! ELLIPSOID GEOMETRY
         QGENNET = (TC-TSKCALCAV)/((SSQG/(2.*AK1*VOL))+
     &    (((((3.*SSQG)**0.5)**3.)/(3.*AK2*VOL))*
     &    ((BS-BG)/(BG*BS))))
        ENDIF
        GO TO 150
       ELSE
C       IF NO, TRY ANOTHER INITIAL TSKIN GUESS AND START THE LOOP OVER AGAIN.
        IF(NTRY < 20.)THEN         
         TSKIN=TSKCALC1
         GO TO 5
        ELSE
         SUCCESS=0.
         IF(IPT.EQ.1.)THEN ! CYLINDER GEOMETRY
          QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(4.*AK1*VOL))+
     &     ((RFLESH**2./(2.*AK2*VOL))*LOG(RSKIN/RFLESH)))
         ENDIF

         IF(IPT.EQ.2.)THEN ! SPHERE GEOMETRY
          QGENNET = (TC-TSKCALCAV)/((RFLESH**2./(6.*AK1*VOL))+
     &    ((RFLESH**3./(3.*AK2*VOL))*((RSKIN-RFLESH)/(RFLESH*RSKIN))))
         ENDIF

         IF(IPT.GE.3.)THEN ! ELLIPSOID GEOMETRY
          QGENNET = (TC-TSKCALCAV)/((SSQG/(2.*AK1*VOL))+
     &    (((((3*SSQG)**0.5)**3.)/(3.*AK2*VOL))*
     &    ((BS-BG)/(BG*BS))))
         ENDIF         
        ENDIF
       ENDIF
105   CONTINUE
      GO TO 150

C     COMMENT: THIS LOOP IS FOR WHEN THERE IS NO FUR.
120   CONTINUE

      NTRY = NTRY + 1       
      DO 140, I=1,20
125     CONTINUE
       CALL CONV_ENDO(TS,TA,SHAPE,CONVSK,FLTYPE,FURTST,D,TFA,VEL,ZFUR,
     &  BP,ALT,CONVRES)
       HC=CONVRES(2)
       HD=CONVRES(5)
       HDFREE=CONVRES(6)
       CALL SEVAP_ENDO(BP,TA,RH,VEL,TC,TSKIN,ALT,SKINW,
     & FLYHR,CONVSK,HD,HDFREE,PCTBAREVAP,PCTEYES,ZFUR,FURWET
     &,TFA, CONVAR, SEVAPRES)
       QSEVAP = SEVAPRES(1)

C      THESE QR VARIABLES INCORPORATE THE VARIOUS HR VALUES FOR RADIANT EXCHANGE WITH SKY, GROUND, ETC.
       QR1=CONVSK*(FASKY*4.*EMIS*SIG*(TSKIN+273.15)**3.)
       QR2=CONVSK*(FABUSH*4.*EMIS*SIG*(TSKIN+273.15)**3.)
       QR3=CONVSK*(FAVEG*4.*EMIS*SIG*(TSKIN+273.15)**3.)
       QR4=CONVSK*(FAGRD*4.*EMIS*SIG*(TSKIN+273.15)**3.)

       TSKT1= ((4.*AK1*VOL)/(RSKIN**2.)*TC)-QSEVAP+HC*CONVSK*
     &  TA+QSLR
       TSKT2= QR1*TSKY+QR2*TBUSH+QR3*TVEG+QR4*TLOWER
       TSKT3=((4.*AK1*VOL)/(RSKIN**2.))+HC*CONVSK+QR1+QR2+
     &  QR3+QR4
       TSKCALC=(TSKT1+TSKT2)/TSKT3

       QRSKY=QR1*(TSKCALC-TSKY)
       QRBSH=QR2*(TSKCALC-TBUSH)
       QRVEG=QR3*(TSKCALC-TVEG)
       QRGRD=QR4*(TSKCALC-TLOWER)
       QRAD = QRSKY+QRBSH+QRVEG+QRGRD
       QCONV = HC*CONVSK*(TSKCALC-TA)
       QENV = QRAD+QCONV-QSLR
       TSKDIFF = ABS(TSKIN-TSKCALC)

C      CHECK TO SEE IF THE TSK GUESS AND CALCULATION ARE SIMILAR
       IF(TSKDIFF.LT.DIFTOL)THEN
C       IF YES, BOTH TFA AND TSK GUESSES ARE SIMILAR TO THE CALCULATED VALUES
        QGENNET = ((4.*AK1*VOL)/RSKIN**2.)*(TC-TSKCALC)
        GO TO 150
       ELSE
C       IF NO, TRY ANOTHER INITIAL TSKIN GUESS AND START THE LOOP OVER AGAIN.
        TSKIN=TSKCALC
        TSKCALCAV=TSKCALC
        TFA=TSKCALC
        NTRY=NTRY+1
        IF(NTRY.EQ.101.)THEN
         IF(DIFTOL.EQ.0.001)THEN
          DIFTOL=0.01
          NTRY=0.
         ELSE
C         CAN'T FIND A SOLUTION, QUIT
          SUCCESS=0.
          QGENNET=0.
         GOTO 150
         ENDIF
        ENDIF
        GO TO 125
       ENDIF
140   CONTINUE

150    CONTINUE
*************************************************************************************************************
C     END CALCULATING TFA AND TSKIN VALUES FOR BARE BODY PARTS
*************************************************************************************************************

      RESULTS = (/TFA,TSKCALCAV,QCONV,QCOND,QGENNET,QSEVAP,QRAD,QSLR,
     & QRSKY,QRBSH,QRVEG,QRGRD,QFSEVAP,NTRY,SUCCESS/) 
    
      RETURN
      END