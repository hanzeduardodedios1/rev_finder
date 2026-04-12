import uuid
import datetime

class RiderLevel():
    BEGINNER = 'Beginner'
    CASUAL = 'Casual'
    INTERMEDIATE = 'Intermediate'
    ADVANCED = 'Advanced'

class MotorcycleSpecs():
    def __init__(self, engineCC: float, seatHeight: float, engineType: str, cylinders: int, horsepower: float,
                torque: float, weight: float, fuelCapacity: float, mpg: float, coolingSystem: str, gearbox: int,
                clutchType: str, frame: str, frontBreakType: str, rearBreakType: str, frontSuspension: str, 
                rearSuspension: str, topSpeed: float):
        
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
        '''Calculate the maximum range of the motorcycle based on fuel capacity and mpg'''
        return self.fuelCapacity * self.mpg
    
    def isBeginnerBike(self):
        '''Determine if a bike is suitable for beginners based on engineCC and horsepower'''
        return self.engineCC <= 500 and self.horsepower <= 60
    
    def powerToWeightRatio(self):
        '''Calculate the power-to-weight ratio of the motorcycle'''
        return self.horsepower / self.weight
    
    def calcPowerScore(self):
        '''Calculate a power score based on horsepower and torque'''
        return self.horsepower * 0.7 + self.torque * 0.3
    
    def calcComfortScore(self):
        '''Calculate a comfort score based on seat height and suspension type'''
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
    

class MotorcycleImage():
    def __init__(self, imageURL: str, imageDescription: str):
        self.imageURL = imageURL
        self.imageDescription = imageDescription


class Motorcycle():
    def __init__(self, make: str, model: str, year: int, category: str, popularityScore: float):
        self._motoID = uuid.uuid1()
        self.make = make
        self.model = model
        self.year = year
        self.category = category
        self.popularityScore = popularityScore

        # This will be used to store the specs of the motorcycle, which can be filled in later when the data is available
        self.specs = None
        self.images = []

    def getFullName(self):
        return str(self.year) + self.make + self.model
    
    def addSpecs(self, specs: MotorcycleSpecs):
        self.specs = specs


class Comparison():
    def __init__(self, motorcycle1: Motorcycle = None, motorcycle2: Motorcycle = None, count: int = 0):
        '''Initializes a comparison object with two motorcycle slots and a count of how many motorcycles are currently in the comparison. The comparison ID is generated using uuid4 for uniqueness, and the creation time is recorded.'''
        self._comparisonID = uuid.uuid4()
        self.motorcycles = [motorcycle1, motorcycle2]
        self.motorcycleCount = count
        self._creationTime = datetime.now()

    def getComparisonID(self):
        '''Returns the unique ID of the comparison.'''
        return self._comparisonID
    
    def getCreationTime(self):
        '''Returns the creation time of the comparison.'''
        return self._creationTime

    def addMotorcycle(self, motorcycle: Motorcycle):
        '''Adds a motorcycle to the comparison. Raises an exception if both slots are already filled.'''
        if self.motorcycleCount < 2:
            if self.motorcycles[0] is None:
                self.motorcycles[0] = motorcycle
            elif self.motorcycles[1] is None:
                self.motorcycles[1] = motorcycle
            self.motorcycleCount += 1
        else:
            raise Exception("Both motorcycle slots are already filled.")
        
    def deleteMotorcycle(self, motorcycle: Motorcycle):
        '''Deletes a motorcycle from the comparison. Raises an exception if the motorcycle is not found in the comparison.'''
        if self.motorcycles[0] == motorcycle:
            self.motorcycles[0] = None
            self.motorcycleCount -= 1
        elif self.motorcycles[1] == motorcycle:
            self.motorcycles[1] = None
            self.motorcycleCount -= 1
        else:
            raise Exception("Motorcycle not found in comparison.")
        
    def deleteComparison(self):
        '''Deletes the entire comparison by resetting the motorcycle slots and count.'''
        self.motorcycles = [None, None]
        self.motorcycleCount = 0

    def findGreaterValue(self, val1, val2):
        '''Compares two values and returns 1 if val1 is greater, -1 if val2 is greater, and 0 if they are equal. Raises an exception if both motorcycle slots are not filled.'''
        if self.motorcycleCount < 2:
            raise Exception("Both motorcycle slots must be filled to compare.")
        if val1 > val2:
            return 1
        elif val1 < val2:
            return -1
        else:
            return 0
        
    def returnComparison(self, greater_val: int, motoValues: list):
        '''Returns the result of a comparison based on the greater value and the corresponding motorcycle. If greater_val is 1, it returns the difference and the first motorcycle. If greater_val is -1, it returns the difference and the second motorcycle. If greater_val is 0, it returns 0.'''
        if greater_val == 1:
            return [motoValues[0] - motoValues[1], self.motorcycles[0]]
        elif greater_val == -1:
            return [motoValues[1] - motoValues[0], self.motorcycles[1]]
        else:
            return 0

    def comparePower(self):
        '''Compares the power score of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.calcPowerScore(), self.motorcycles[1].specs.calcPowerScore())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.calcPowerScore(), self.motorcycles[1].specs.calcPowerScore()])

    def compareComfort(self):
        '''Compares the comfort score of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.calcComfortScore(), self.motorcycles[1].specs.calcComfortScore())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.calcComfortScore(), self.motorcycles[1].specs.calcComfortScore()])

    def compareRange(self):
        '''Compares the maximum range of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.calcMaxRange(), self.motorcycles[1].specs.calcMaxRange())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.calcMaxRange(), self.motorcycles[1].specs.calcMaxRange()])

    def compareHorsepower(self):
        '''Compares the horsepower of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.horsepower, self.motorcycles[1].specs.horsepower)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.horsepower, self.motorcycles[1].specs.horsepower])
    
    def compareTorque(self):
        '''Compares the torque of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.torque, self.motorcycles[1].specs.torque)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.torque, self.motorcycles[1].specs.torque])
    
    def compareWeight(self):
        '''Compares the weight of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.weight, self.motorcycles[1].specs.weight)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.weight, self.motorcycles[1].specs.weight]) 
    
    def compareMPG(self):
        '''Compares the miles per gallon of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.mpg, self.motorcycles[1].specs.mpg)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.mpg, self.motorcycles[1].specs.mpg])
    
    def compareTopSpeed(self):
        '''Compares the top speed of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.topSpeed, self.motorcycles[1].specs.topSpeed)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.topSpeed, self.motorcycles[1].specs.topSpeed])
    
    def comparePowerToWeight(self):
        '''Compares the power-to-weight ratio of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.powerToWeightRatio(), self.motorcycles[1].specs.powerToWeightRatio())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.powerToWeightRatio(), self.motorcycles[1].specs.powerToWeightRatio()])
    
    def compareSeatHeight(self):
        '''Compares the seat height of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.seatHeight, self.motorcycles[1].specs.seatHeight)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.seatHeight, self.motorcycles[1].specs.seatHeight])
    
    def compareEngineCC(self):
        '''Compares the engine displacement (CC) of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.engineCC, self.motorcycles[1].specs.engineCC)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.engineCC, self.motorcycles[1].specs.engineCC])
    
    def compareCylinders(self):
        '''Compares the number of cylinders of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.cylinders, self.motorcycles[1].specs.cylinders)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.cylinders, self.motorcycles[1].specs.cylinders])
    
    def compareFuelCapacity(self):
        '''Compares the fuel capacity of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.fuelCapacity, self.motorcycles[1].specs.fuelCapacity)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.fuelCapacity, self.motorcycles[1].specs.fuelCapacity])
    
    def compareGearbox(self):
        '''Compares the number of gears in the gearbox of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.gearbox, self.motorcycles[1].specs.gearbox)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.gearbox, self.motorcycles[1].specs.gearbox])


class User():
    def __init__(self, name: str, email: str, phoneNo: int, MotoHistory: list, UserVerified: bool, riderLevel, passwordHash: str, isActive: bool, comparisonHistory: list = None):
        self._userID = uuid.uuid4()
        self._name = name
        self._email = email
        self._phoneNo = phoneNo
        self._MotoHistory = MotoHistory
        self._UserVerified = UserVerified
        self._riderLevel = riderLevel
        self._passwordHash = passwordHash
        self._isActive = isActive
        self._creationTime = datetime.now()
        self._comparisonHistory = comparisonHistory

    def requestVerification(self, method):
        # Implement verification using external software?
        pass

    def markPurchased(self, motorcycle: Motorcycle):
        # Using the assumption that MotoHistory represents the motorcycles the user has marked as purchased
        self.MotoHistory.append(motorcycle)

    def addComparison(self, comparison: Comparison):
        if self._comparisonHistory is None:
            self._comparisonHistory = []
        self._comparisonHistory.append(comparison)
        



    