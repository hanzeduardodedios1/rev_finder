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


class MotorcycleSpecs():
    def __init__(self, engineCC: int, seatHeight: float, engineType: str, cylinders: int, horsepower: float,
                  torque: float, weight: float, fuelCapacity: float, mpg: float):
        self.engineCC = engineCC
        self.seatHeight = seatHeight
        self.engineType = engineType
        self.cylinders = cylinders
        self.horsepower = horsepower
        self.torque = torque
        self.weight = weight
        self.fuelCapacity = fuelCapacity
        self.mpg = mpg

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


class Compairson():
    
        