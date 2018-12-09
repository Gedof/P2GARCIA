{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE DeriveGeneric #-}
module Handler.Paciente where

import Import
import Network.HTTP.Types.Status
import Database.Persist.Postgresql
import Text.Lucius
import Text.Julius
import Data.Time
import Data.Aeson
import Data.Aeson.Casing


data PacReqJSON = PacReqJSON {
    pacreqNome          :: Text,
    pacreqCpf           :: Text,
    pacreqRg            :: Text,
    pacreqNasc          :: Day,
    pacreqTelefone      :: Maybe Text,
    pacreqCelular       :: Maybe Text,
    pacreqEmail         :: Text,
    pacreqCep           :: Text,
    pacreqEstado        :: Text,
    pacreqCidade        :: Text,
    pacreqBairro        :: Text,
    pacreqLogradouro    :: Text,
    pacreqNumero        :: Text,
    pacreqComplemento   :: Maybe Text
} deriving (Show, Read, Generic)

instance ToJSON PacReqJSON where
   toJSON = genericToJSON $ aesonPrefix snakeCase
instance FromJSON PacReqJSON where
   parseJSON = genericParseJSON $ aesonPrefix snakeCase


postPacienteR :: Handler TypedContent
postPacienteR = do
    addHeader "ACCESS-CONTROL-ALLOW-ORIGIN" "*"
    pacjson <- requireJsonBody :: Handler PacReqJSON
    agora <- liftIO $ getCurrentTime
    paciente <- return $ createPaciente agora pacjson
    pacienteid <- runDB $ insert paciente
    sendStatusJSON created201 (object ["id" .= pacienteid])
    
    
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