--[=[
    @class DataConfig

    Configuration and constants for the DataService.
    Centralizes all data-related settings for easy management.
]=]

local RunService = game:GetService("RunService")

local DataConfig = {}

DataConfig.DATASTORE_NAME = RunService:IsStudio() and "PlayerData_TestNew1" or "PlayerData_V2"
DataConfig.GLOBAL_DATASTORE_NAME = "GlobalData"

DataConfig.MESSAGE_TOPIC = "GlobalDataUpdate"

DataConfig.SHORT_ID_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
DataConfig.SHORT_ID_LENGTH = 10
DataConfig.HEX_ALPHABET = "0123456789abcdef"
DataConfig.READABLE_CONSONANTS = "bcdfghjklmnpqrstvwxyz"
DataConfig.READABLE_VOWELS = "aeiou"

DataConfig.GLOBAL_KEYS = {
	LEADERBOARD_DATA = "LeaderboardData",
}

return DataConfig
