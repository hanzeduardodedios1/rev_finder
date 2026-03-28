import uuid
import datetime

class Motorcycle():
    def __init__(self, make: str, model: str, year: int, category: str, popularityScore: float):
        self.motoID = uuid.uuid1()
        self.make = make
        self.model = model
        self.year = year
        self.category = category
        self.popularityScore = popularityScore

    def getFullName(self):
        return str(self.year) + self.make + self.model



class User():
    def __init__(self, name: str, email: str, phoneNo: int, MotoHistory: list, UserVerified: bool, riderLevel, passwordHash: str, isActive: bool):
        self.userID = uuid.uuid1()
        self.name = name
        self.email = email
        self.phoneNo = phoneNo
        self.MotoHistory = MotoHistory
        self.UserVerified = UserVerified
        self.riderLevel = riderLevel
        self.passwordHash = passwordHash
        self.isActive = isActive
        self.creationTime = datetime.now()

    def requestVerification(self, method):
        # Implement verification using external software?
        pass

    def markPurchased(self, motorcycle: Motorcycle):
        # Using the assumption that MotoHistory represents the motorcycles the user has marked as purchased
        self.MotoHistory.append(motorcycle)