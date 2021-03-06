{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE DeriveGeneric #-}
module Handler.Paciente where

import Import
import Database.Persist.Postgresql
import Data.Time
import Data.Aeson
import Data.Aeson.Casing
import Handler.Prontuario
import Handler.Consulta
import Data.Text as T (pack,unpack,Text)
import Handler.Login

--POST



--Criando o tipo JSON para receber um novo paciente
data PacReqJSON = PacReqJSON {
    pacreqNome          :: Text,
    pacreqCpf           :: Text,
    pacreqRg            :: Text,
    pacreqNasc          :: Maybe Day,
    pacreqTelefone      :: Maybe Text,
    pacreqCelular       :: Maybe Text,
    pacreqEmail         :: Text,
    pacreqCep           :: Maybe Text,
    pacreqEstado        :: Maybe Text,
    pacreqCidade        :: Maybe Text,
    pacreqBairro        :: Maybe Text,
    pacreqLogradouro    :: Maybe Text,
    pacreqNumero        :: Maybe Text,
    pacreqComplemento   :: Maybe Text
} deriving (Show, Read, Generic)
--Criando instância de ToJSON e FromJSON
instance ToJSON PacReqJSON where
   toJSON = genericToJSON $ aesonPrefix snakeCase
instance FromJSON PacReqJSON where
   parseJSON = genericParseJSON $ aesonPrefix snakeCase


optionsPacienteR :: Handler TypedContent
optionsPacienteR = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    sendStatusJSON ok200 (object [])

--Função que receberá o POST de paciente
postPacienteR :: Handler TypedContent
postPacienteR = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    pacjson <- requireJsonBody :: Handler PacReqJSON
    mBearer <- lookupBearerAuth
    execJwt mBearer [1,2,3] $ do
        agora <- liftIO $ getCurrentTime
        paciente <- return $ createPaciente agora pacjson
        pacienteid <- runDB $ insert paciente
        sendStatusJSON created201 (object ["resp" .= pacienteid])

--Função que pega o tempo de agora e o JSON postado para criar o tipo paciente (usado no banco)    
createPaciente :: UTCTime -> PacReqJSON -> Paciente
createPaciente agora pacjson = 
    Paciente {
        pacienteNome                    = pacreqNome pacjson,
        pacienteCpf                     = pacreqCpf pacjson,
        pacienteRg                      = pacreqRg pacjson,
        pacienteNasc                    = pacreqNasc pacjson,
        pacienteTelefone                = pacreqTelefone pacjson,
        pacienteCelular                 = pacreqCelular pacjson,
        pacienteEmail                   = pacreqEmail pacjson,
        pacientePais                    = "BR",
        pacienteCep                     = pacreqCep pacjson,
        pacienteEstado                  = pacreqEstado pacjson,
        pacienteCidade                  = pacreqCidade pacjson,
        pacienteBairro                  = pacreqBairro pacjson,
        pacienteLogradouro              = pacreqLogradouro pacjson,
        pacienteNumero                  = pacreqNumero pacjson,
        pacienteComplemento             = pacreqComplemento pacjson,
        pacienteInsertedTimestamp       = agora,
        pacienteLastUpdatedTimestamp    = agora
    }
    
--GET 1
    
--Criando o tipo JSON que mandará o paciente selecionado para o front    
data PacResJSON = PacResJSON {
    pacresId            :: PacienteId,
    pacresNome          :: Text,
    pacresCpf           :: Text,
    pacresRg            :: Text,
    pacresNasc          :: Maybe Day,
    pacresTelefone      :: Maybe Text,
    pacresCelular       :: Maybe Text,
    pacresEmail         :: Text,
    pacresCep           :: Maybe Text,
    pacresEstado        :: Maybe Text,
    pacresCidade        :: Maybe Text,
    pacresBairro        :: Maybe Text,
    pacresLogradouro    :: Maybe Text,
    pacresNumero        :: Maybe Text,
    pacresComplemento   :: Maybe Text,
    pacresInsertedTimestamp     :: ZonedTime,
    pacresLastUpdatedTimestamp  :: ZonedTime
} deriving (Show, Read, Generic)

instance ToJSON PacResJSON where
   toJSON = genericToJSON $ aesonPrefix snakeCase
instance FromJSON PacResJSON where
   parseJSON = genericParseJSON $ aesonPrefix snakeCase
  

optionsSinglePacienteR :: PacienteId -> Handler TypedContent
optionsSinglePacienteR _ = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    sendStatusJSON ok200 (object [])

--Função que receberá o GET e responderá com o JSON do paciente
getSinglePacienteR :: PacienteId -> Handler TypedContent
getSinglePacienteR pacid = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    mBearer <- lookupBearerAuth
    execJwt mBearer [1,2,3] $ do
        paciente <- runDB $ get404 pacid
        pacjson <- return $ createPacGet pacid paciente
        sendStatusJSON ok200 (object ["resp" .= pacjson])

--Função que recebe um id e o tipo Paciente (do banco) para criar o JSON de resposta
createPacGet :: PacienteId -> Paciente -> PacResJSON
createPacGet pacienteid pac =
    PacResJSON {
        pacresId            = pacienteid,
        pacresNome          = pacienteNome pac,
        pacresCpf           = pacienteCpf pac,
        pacresRg            = pacienteRg pac,
        pacresNasc          = pacienteNasc pac,
        pacresTelefone      = pacienteTelefone pac,
        pacresCelular       = pacienteCelular pac,
        pacresEmail         = pacienteEmail pac,
        pacresCep           = pacienteCep pac,
        pacresEstado        = pacienteEstado pac,
        pacresCidade        = pacienteCidade pac,
        pacresBairro        = pacienteBairro pac,
        pacresLogradouro    = pacienteLogradouro pac,
        pacresNumero        = pacienteNumero pac,
        pacresComplemento   = pacienteComplemento pac,
        pacresInsertedTimestamp     = istamp,
        pacresLastUpdatedTimestamp  = ustamp
    }
    where
    istamp = utcToZonedTime utc $ pacienteInsertedTimestamp pac
    ustamp = utcToZonedTime utc $ pacienteLastUpdatedTimestamp pac


--GET LIST

--Função que pegará uma "Entidade Paciente" (tipo que vem do banco (id+Paciente)) e criará um JSON de resposta
createPacGetE :: Entity Paciente -> PacResJSON
createPacGetE ePaciente = createPacGet pacienteid paciente
    where
    pacienteid = entityKey ePaciente
    paciente = entityVal ePaciente
    
    
optionsListPacienteR :: Handler TypedContent
optionsListPacienteR = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    sendStatusJSON ok200 (object [])

--Função que receberá o GET para a listagem de todos os pacientes
getListPacienteR :: Handler TypedContent
getListPacienteR = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    mNome <- lookupGetParam $ T.pack "nome"
    mRg <- lookupGetParam $ T.pack "rg"
    mCpf <- lookupGetParam $ T.pack "cpf"
    mBearer <- lookupBearerAuth
    execJwt mBearer [1,2,3] $ do
        nomeFilter <- return $ createPacFilterNome mNome
        rgFilter <- return $ createPacFilterRg mRg
        cpfFilter <- return $ createPacFilterCpf mCpf
        ePacientes <- runDB $ selectList (concat [nomeFilter, rgFilter, cpfFilter]) [Asc PacienteId]
        pacjsons <- return $ map createPacGetE ePacientes
        sendStatusJSON ok200 (object ["resp" .= pacjsons])
    
    
createPacFilterNome :: Maybe Text -> [Filter Paciente]
createPacFilterNome mNome = 
    case mNome of
        Just nome -> [Filter PacienteNome (Left $ concat ["%", nome, "%"]) (BackendSpecificFilter "ILIKE")]
        Nothing -> []
        
createPacFilterRg :: Maybe Text -> [Filter Paciente]
createPacFilterRg mRg = 
    case mRg of
        Just rg -> [Filter PacienteRg (Left $ concat ["%", rg, "%"]) (BackendSpecificFilter "ILIKE")]
        Nothing -> []

createPacFilterCpf :: Maybe Text -> [Filter Paciente]
createPacFilterCpf mCpf = 
    case mCpf of
        Just cpf -> [Filter PacienteCpf (Left $ concat ["%", cpf, "%"]) (BackendSpecificFilter "ILIKE")]
        Nothing -> []
    
--DELETE

optionsApagarPacienteR :: PacienteId -> Handler TypedContent
optionsApagarPacienteR _ = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    addHeader "ACCESS-CONTROL-ALLOW-METHODS" "DELETE"
    sendStatusJSON ok200 (object [])


--Função que receberá o DELETE com um Id e apaga o paciente do banco de dados
--(ainda incompleto, pois dependeria do apagar consulta e prontuário também)
deleteApagarPacienteR :: PacienteId -> Handler TypedContent
deleteApagarPacienteR pacid = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    addHeader "ACCESS-CONTROL-ALLOW-METHODS" "DELETE"
    mBearer <- lookupBearerAuth
    execJwt mBearer [1] $ do
        _ <- runDB $ get404 pacid
        eCons <- runDB $ selectList [ConsultaPacienteid ==. pacid] [Asc ConsultaId]
        ePronts <- runDB $ selectList [EntradaProntuarioPacienteid ==. pacid] [Asc EntradaProntuarioId]
        _ <- mapM apagaCons eCons
        _ <- mapM apagaPront ePronts
        runDB $ delete pacid
        sendStatusJSON ok200 (object ["resp" .= ("Paciente deletado"::Text)]) 
    where
    apagaCons eCon = deleteApagarConsultaR (entityKey eCon)
    apagaPront ePront = deleteApagarProntuarioR (entityKey ePront)


--PUT

--Cria um Paciente com as informações novas, porém mantendo a data de criação antiga.
alterPaciente :: PacReqJSON -> Paciente -> UTCTime -> Paciente
alterPaciente pacjson paciente agora = 
    Paciente {
        pacienteNome                    = pacreqNome pacjson,
        pacienteCpf                     = pacreqCpf pacjson,
        pacienteRg                      = pacreqRg pacjson,
        pacienteNasc                    = pacreqNasc pacjson,
        pacienteTelefone                = pacreqTelefone pacjson,
        pacienteCelular                 = pacreqCelular pacjson,
        pacienteEmail                   = pacreqEmail pacjson,
        pacientePais                    = "BR",
        pacienteCep                     = pacreqCep pacjson,
        pacienteEstado                  = pacreqEstado pacjson,
        pacienteCidade                  = pacreqCidade pacjson,
        pacienteBairro                  = pacreqBairro pacjson,
        pacienteLogradouro              = pacreqLogradouro pacjson,
        pacienteNumero                  = pacreqNumero pacjson,
        pacienteComplemento             = pacreqComplemento pacjson,
        pacienteInsertedTimestamp       = pacienteInsertedTimestamp paciente,
        pacienteLastUpdatedTimestamp    = agora
    }

optionsAlterarPacienteR :: PacienteId -> Handler TypedContent
optionsAlterarPacienteR _ = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    addHeader "ACCESS-CONTROL-ALLOW-METHODS" "PUT"
    sendStatusJSON ok200 (object [])

--Função que receberá o PUT com um Id e as novas informações do paciente, colocando no banco com o mesmo id
putAlterarPacienteR :: PacienteId -> Handler TypedContent
putAlterarPacienteR pacid = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    addHeader "ACCESS-CONTROL-ALLOW-HEADERS" "AUTHORIZATION"
    addHeader "ACCESS-CONTROL-ALLOW-METHODS" "PUT"
    paciente <- runDB $ get404 pacid
    pacjson <- requireJsonBody :: Handler PacReqJSON
    mBearer <- lookupBearerAuth
    execJwt mBearer [1,2] $ do
        agora <- liftIO $ getCurrentTime
        altPaciente <- return $ alterPaciente pacjson paciente agora
        runDB $ replace pacid altPaciente
        sendStatusJSON ok200 (object ["resp" .= ("Paciente alterado"::Text)])
    