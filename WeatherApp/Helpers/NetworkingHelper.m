//
//  NetworkingHelper.m
//  WeatherApp
//
//  Created by Renzo Crisóstomo on 1/14/14.
//  Copyright (c) 2014 Ruenzuo. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <AFNetworking/AFNetworking.h>
#import <TMCache/TMCache.h>
#import "NetworkingHelper.h"
#import "Country.h"
#import "TranslatorHelper.h"
#import "Blocks.h"

@interface NetworkingHelper ()

@property (nonatomic, strong) TranslatorHelper *translatorHelper;

+ (AFHTTPRequestOperation *)createHTTPRequestOperationWithConfiguration:(RequestOperationConfigBlock)configuration;

@end

@implementation NetworkingHelper
{
}

#pragma mark - Lazy Loading Pattern

- (TranslatorHelper *)translatorHelper
{
    if (_translatorHelper == nil) {
        _translatorHelper = [[TranslatorHelper alloc] init];
    }
    return _translatorHelper;
}

#pragma mark - Private Methods

+ (AFHTTPRequestOperation *)createHTTPRequestOperationWithConfiguration:(RequestOperationConfigBlock)configuration
{
    NSParameterAssert(configuration != nil);
    RequestOperationConfig* requestOperationConfig = [[RequestOperationConfig alloc] init];
    if (configuration) {
        configuration(requestOperationConfig);
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:[requestOperationConfig URL]];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer = requestOperationConfig.responseSerializer;
    return requestOperation;
}

#pragma mark - Cities Protocol

- (void)getCitiesFromLatitude:(double)latitude
                    longitude:(double)longitude
                   completion:(ArrayCompletionBlock)completion
{
    AFHTTPRequestOperation *requestOperation = [NetworkingHelper createHTTPRequestOperationWithConfiguration:^(RequestOperationConfig *config) {
        config.URL = [NSURL URLWithString:@"http://api.openweathermap.org/data/2.5/find?lat=57&lon=-2.15"];
        config.responseSerializer = [AFJSONResponseSerializer serializer];
    }];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

#pragma mark - Countries Protocol

- (void)getCountriesWithCompletion:(ArrayCompletionBlock)completion
{
    AFHTTPRequestOperation *requestOperation = [NetworkingHelper createHTTPRequestOperationWithConfiguration:^(RequestOperationConfig *config) {
        config.URL = [NSURL URLWithString:@"http://api.geonames.org/countryInfoJSON?username=WeatherApp"];
        config.responseSerializer = [AFJSONResponseSerializer serializer];
    }];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!completion) {
            return;
        }
        NSArray *collection = [[self translatorHelper] translateCollectionFromJSON:[responseObject objectForKey:@"geonames"]
                                                                     withClassName:@"Country"];
        [[TMCache sharedCache] setObject:collection
                                  forKey:@"Countries"
                                   block:nil];
        completion(collection, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

@end