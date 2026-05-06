# classes.py
#
# Backend domain classes for RevFinder.
#
# MotorcycleSpecs stores already-parsed/normalized motorcycle values.
# The backend uses this class to calculate comparison metrics and then returns
# clear JSON to the frontend.
#
# Updated:
# - Power score now calculates from available power-related values.
# - Comfort score now calculates from available comfort-related values.
# - Scores return None only when no usable score inputs exist.

import uuid
import datetime


class RiderLevel:
    BEGINNER = "Beginner"
    CASUAL = "Casual"
    INTERMEDIATE = "Intermediate"
    ADVANCED = "Advanced"


class MotorcycleCategory:
    SPORT = "Sport"
    CRUISER = "Cruiser"
    TOURING = "Touring"
    STANDARD = "Standard"
    DUAL_SPORT = "Dual-Sport"
    OFF_ROAD = "Off-Road"


class MotorcycleSpecs:
    def __init__(
        self,
        engineCC=None,
        seatHeightIn=None,
        engineType=None,
        cylinders=None,
        horsepower=None,
        torqueLbFt=None,
        weightLb=None,
        fuelCapacityGal=None,
        mpg=None,
        coolingSystem=None,
        gearbox=None,
        clutchType=None,
        frame=None,
        frontBrakeType=None,
        rearBrakeType=None,
        frontSuspension=None,
        rearSuspension=None,
        topSpeedMph=None,
    ):
        self.engineCC = engineCC
        self.seatHeightIn = seatHeightIn
        self.cylinders = cylinders
        self.horsepower = horsepower
        self.torqueLbFt = torqueLbFt
        self.weightLb = weightLb
        self.fuelCapacityGal = fuelCapacityGal
        self.mpg = mpg
        self.gearbox = gearbox
        self.topSpeedMph = topSpeedMph

        self.engineType = engineType
        self.coolingSystem = coolingSystem
        self.clutchType = clutchType
        self.frame = frame
        self.frontBrakeType = frontBrakeType
        self.rearBrakeType = rearBrakeType
        self.frontSuspension = frontSuspension
        self.rearSuspension = rearSuspension

    def _has_all_required(self, values):
        return all(value is not None for value in values)

    def calcSuspensionScore(self):
        """
        Calculate suspension quality score from front/rear suspension text.

        Returns:
            float | None
        """
        if not self._has_all_required([self.frontSuspension, self.rearSuspension]):
            return None

        front = str(self.frontSuspension).lower()
        rear = str(self.rearSuspension).lower()

        front_scores = {
            "inverted fork": 8.5,
            "upside-down fork": 8.5,
            "usd fork": 8.5,
            "cartridge fork": 8.0,
            "showa sff-bp fork": 8.5,
            "showa sff-ca fork": 8.5,
            "hmas cartridge fork": 8.0,
            "telescopic fork": 6.5,
            "conventional fork": 6.0,
            "fork": 6.0,
        }

        rear_scores = {
            "single shock": 8.0,
            "monoshock": 8.0,
            "mono-shock": 8.0,
            "horizontal monoshock": 8.0,
            "horizontal back-link": 8.0,
            "back-link": 8.0,
            "pro-link": 8.0,
            "unitrak": 8.0,
            "uni-trak": 8.0,
            "linkage": 7.8,
            "swingarm": 7.0,
            "twin shock": 5.5,
            "dual shock": 5.5,
            "shock absorber": 6.5,
            "rear shock": 6.5,
        }

        bonuses = {
            "fully adjustable": 2.0,
            "adjustable": 1.0,
            "adjustability": 1.0,
            "preload": 0.8,
            "compression damping": 1.0,
            "rebound damping": 1.0,
            "compression": 0.5,
            "rebound": 0.5,
            "gas-charged": 0.5,
            "remote": 0.3,
        }

        front_score = 5.5
        rear_score = 5.5

        for term, score in front_scores.items():
            if term in front:
                front_score = max(front_score, score)

        for term, score in rear_scores.items():
            if term in rear:
                rear_score = max(rear_score, score)

        bonus = 0.0
        combined = f"{front} {rear}"

        for term, points in bonuses.items():
            if term in combined:
                bonus += points

        total = ((front_score + rear_score) / 2) + bonus

        return round(min(total, 10.0), 2)

    def calcMaxRange(self):
        if not self._has_all_required([self.fuelCapacityGal, self.mpg]):
            return None

        return round(self.fuelCapacityGal * self.mpg, 2)

    def isBeginnerBike(self):
        if not self._has_all_required([self.engineCC, self.horsepower]):
            return None

        return self.engineCC <= 500 and self.horsepower <= 60

    def powerToWeightRatio(self):
        if not self._has_all_required([self.horsepower, self.weightLb]):
            return None

        if self.weightLb == 0:
            return None

        return round(self.horsepower / self.weightLb, 4)

    def calcPowerScore(self):
        """
        Calculate a 0-100 power score using available data.

        Components:
        - horsepower: up to 35 points
        - torque: up to 25 points
        - engineCC: up to 20 points
        - cylinders: up to 10 points
        - power-to-weight ratio: up to 10 points

        Returns:
            float | None
        """
        score = 0.0
        possible_points = 0.0

        if self.horsepower is not None:
            score += min(self.horsepower / 200, 1.0) * 35
            possible_points += 35

        if self.torqueLbFt is not None:
            score += min(self.torqueLbFt / 100, 1.0) * 25
            possible_points += 25

        if self.engineCC is not None:
            score += min(self.engineCC / 1000, 1.0) * 20
            possible_points += 20

        if self.cylinders is not None:
            score += min(self.cylinders / 4, 1.0) * 10
            possible_points += 10

        if self.horsepower is not None and self.weightLb is not None and self.weightLb > 0:
            power_to_weight = self.horsepower / self.weightLb
            score += min(power_to_weight / 0.45, 1.0) * 10
            possible_points += 10

        if possible_points == 0:
            return None

        return round((score / possible_points) * 100, 2)

    def calcComfortScore(self):
        """
        Calculate a 0-100 comfort score using available data.

        Components:
        - mpg: up to 20 points
        - fuel capacity: up to 15 points
        - gearbox: up to 10 points
        - suspension score: up to 20 points
        - clutch type: up to 10 points
        - weight: up to 15 points
        - seat height: up to 10 points

        Returns:
            float | None
        """
        score = 0.0
        possible_points = 0.0

        if self.mpg is not None:
            score += min(self.mpg / 60, 1.0) * 20
            possible_points += 20

        if self.fuelCapacityGal is not None:
            score += min(self.fuelCapacityGal / 5, 1.0) * 15
            possible_points += 15

        if self.gearbox is not None:
            score += min(self.gearbox / 6, 1.0) * 10
            possible_points += 10

        suspension_score = self.calcSuspensionScore()
        if suspension_score is not None:
            score += min(suspension_score / 10, 1.0) * 20
            possible_points += 20

        if self.clutchType is not None:
            clutch_score = 5
            clutch_type = str(self.clutchType).lower()

            if "slipper" in clutch_type:
                clutch_score += 2

            if "assist" in clutch_type:
                clutch_score += 2

            if "hydraulic" in clutch_type:
                clutch_score += 1

            score += min(clutch_score, 10)
            possible_points += 10

        if self.weightLb is not None:
            if self.weightLb <= 350:
                weight_score = 15
            elif self.weightLb >= 650:
                weight_score = 0
            else:
                weight_score = ((650 - self.weightLb) / 300) * 15

            score += weight_score
            possible_points += 15

        if self.seatHeightIn is not None:
            ideal_seat_height = 31.0
            difference = abs(self.seatHeightIn - ideal_seat_height)
            seat_score = max(0, 10 - ((difference / 6) * 10))

            score += seat_score
            possible_points += 10

        if possible_points == 0:
            return None

        return round((score / possible_points) * 100, 2)

    def to_dict(self):
        return {
            "parsed_engine_cc": self.engineCC,
            "parsed_horsepower": self.horsepower,
            "parsed_torque_lb_ft": self.torqueLbFt,
            "parsed_weight_lb": self.weightLb,
            "parsed_seat_height_in": self.seatHeightIn,
            "parsed_fuel_capacity_gal": self.fuelCapacityGal,
            "parsed_mpg": self.mpg,

            "engine_cc": self.engineCC,
            "horsepower": self.horsepower,
            "torque": self.torqueLbFt,
            "weight": self.weightLb,
            "seat_height": self.seatHeightIn,
            "fuel_capacity": self.fuelCapacityGal,
            "fuel_capacity_gallons": self.fuelCapacityGal,
            "mpg": self.mpg,

            "engine_type": self.engineType,
            "cylinders": self.cylinders,
            "cooling_system": self.coolingSystem,
            "gearbox": self.gearbox,
            "clutch_type": self.clutchType,
            "frame": self.frame,
            "front_brake_type": self.frontBrakeType,
            "rear_brake_type": self.rearBrakeType,
            "front_suspension": self.frontSuspension,
            "rear_suspension": self.rearSuspension,
            "top_speed": self.topSpeedMph,

            "suspension_score": self.calcSuspensionScore(),
            "power_score": self.calcPowerScore(),
            "comfort_score": self.calcComfortScore(),
            "power_to_weight_ratio": self.powerToWeightRatio(),
            "max_range": self.calcMaxRange(),
            "is_beginner_bike": self.isBeginnerBike(),
        }


class MotorcycleImage:
    def __init__(self, imageURL: str, imageDescription: str):
        self.imageURL = imageURL
        self.imageDescription = imageDescription


class Motorcycle:
    def __init__(
        self,
        make: str,
        model: str,
        year: int,
        category: str,
        popularityScore: float,
    ):
        self._motoID = uuid.uuid4()
        self.make = make
        self.model = model
        self.year = year
        self.category = category
        self.popularityScore = popularityScore
        self.specs = None
        self.images = []

    def getFullName(self):
        return f"{self.year} {self.make} {self.model}"

    def addSpecs(self, specs: MotorcycleSpecs):
        self.specs = specs

    def getMotoID(self):
        return self._motoID


class Comparison:
    def __init__(self, motorcycle1: Motorcycle = None, motorcycle2: Motorcycle = None, count: int = 0):
        self._comparisonID = uuid.uuid4()
        self.motorcycles = [motorcycle1, motorcycle2]
        self.motorcycleCount = count
        self._creationTime = datetime.datetime.now()

    def getComparisonID(self):
        return self._comparisonID

    def getCreationTime(self):
        return self._creationTime

    def addMotorcycle(self, motorcycle: Motorcycle):
        if self.motorcycleCount < 2:
            if self.motorcycles[0] is None:
                self.motorcycles[0] = motorcycle
            elif self.motorcycles[1] is None:
                self.motorcycles[1] = motorcycle

            self.motorcycleCount += 1
        else:
            raise Exception("Both motorcycle slots are already filled.")

    def deleteMotorcycle(self, motorcycle: Motorcycle):
        if self.motorcycles[0] == motorcycle:
            self.motorcycles[0] = None
            self.motorcycleCount -= 1
        elif self.motorcycles[1] == motorcycle:
            self.motorcycles[1] = None
            self.motorcycleCount -= 1
        else:
            raise Exception("Motorcycle not found in comparison.")

    def getMotorcycles(self):
        return self.motorcycles

    def getMotorcycleCount(self):
        return self.motorcycleCount

    def clearComparison(self):
        self.motorcycles = [None, None]
        self.motorcycleCount = 0


class User:
    def __init__(
        self,
        name: str,
        email: str,
        phoneNo: int,
        MotoHistory: list,
        UserVerified: bool,
        riderLevel,
        passwordHash: str,
        isActive: bool,
        comparisonHistory: list = None,
    ):
        self._userID = uuid.uuid4()
        self._name = name
        self._email = email
        self._phoneNo = phoneNo
        self._MotoHistory = MotoHistory
        self._UserVerified = UserVerified
        self._riderLevel = riderLevel
        self._passwordHash = passwordHash
        self._isActive = isActive
        self._creationTime = datetime.datetime.now()
        self._comparisonHistory = comparisonHistory


class Purchase:
    def __init__(self, user_id: uuid.UUID, motorcycle_id: uuid.UUID):
        self.purchaseID = uuid.uuid1()
        self.userID = user_id
        self.motorcycleID = motorcycle_id
        self.purchaseDate = datetime.datetime.now()
        self.verified = False
        self.created_at = datetime.datetime.now()

    def verify_purchase(self):
        self.verified = True


class Favorite:
    def __init__(self, user_id: uuid.UUID, motorcycle_id: uuid.UUID):
        self.favoriteID = uuid.uuid1()
        self.userID = user_id
        self.motorcycleID = motorcycle_id
        self.created_at = datetime.datetime.now()

    def getMotorcycleID(self):
        return self.motorcycleID


class Review:
    def __init__(self, user_id: uuid.UUID, motorcycle_id: uuid.UUID, rating: int, message: str = ""):
        self.reviewID = uuid.uuid1()
        self.userID = user_id
        self.motorcycleID = motorcycle_id
        self.rating = rating
        self.message = message
        self.created_at = datetime.datetime.now()

    def getRating(self):
        return self.rating