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

        # This will be used to store the specs of the motorcycle, which can be filled in later when the data is available
        self.specs = None

    def getFullName(self):
        return str(self.year) + self.make + self.model


class MotorcycleSpecs():
    def __init__(self, engineCC: int, seatHeight: float, engineType: str, cylinders: int, horsepower: float,
                torque: float, weight: float, fuelCapacity: float, mpg: float, coolingSystem: str, gearbox: str,
                clutchType: str, frame: str, frontBreakType: str, rearBreakType: str, frontSuspension: str, 
                rearSuspension: str, topSpeed: float, ):
        
        self.engineCC = engineCC
        self.seatHeight = seatHeight
        self.engineType = engineType
        self.cylinders = cylinders
        self.horsepower = horsepower
        self.torque = torque
        self.weight = weight
        self.fuelCapacity = fuelCapacity
        self.mpg = mpg
        self.coolingSystem = coolingSystem
        self.gearbox = gearbox
        self.clutchType = clutchType
        self.frame = frame
        self.frontBreakType = frontBreakType
        self.rearBreakType = rearBreakType
        self.frontSuspension = frontSuspension
        self.rearSuspension = rearSuspension
        self.topSpeed = topSpeed

    def calcMaxRange(self):
        # Calculate the maximum range of the motorcycle based on fuel capacity and mpg
        return self.fuelCapacity * self.mpg
    
    def isBeginnerBike(self):
        # A simple heuristic to determine if a bike is suitable for beginners based on engineCC and horsepower
        return self.engineCC <= 500 and self.horsepower <= 60
    
    def powerToWeightRatio(self):
        # Calculate the power-to-weight ratio of the motorcycle
        return self.horsepower / self.weight
    
    def calcPowerScore(self):
        # A simple formula to calculate a power score based on horsepower and torque
        return self.horsepower * 0.7 + self.torque * 0.3
    
    def calcComfortScore(self):
        # A simple formula to calculate a comfort score based on seat height and suspension type
        comfortScore = 0
        if self.seatHeight < 30:
            comfortScore += 5
        elif self.seatHeight < 35:
            comfortScore += 3
        else:
            comfortScore += 1
        
        if self.frontSuspension == 'inverted' and self.rearSuspension == 'monoshock':
            comfortScore += 5
        elif self.frontSuspension == 'telescopic' and self.rearSuspension == 'twin shock':
            comfortScore += 3
        else:
            comfortScore += 1
        
        return comfortScore


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
    
        