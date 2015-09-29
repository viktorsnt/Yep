//
//  FeedsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class FeedsViewController: UIViewController {

    @IBOutlet weak var feedsCollectionView: UICollectionView!

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.feedsCollectionView.bounds)
        }()

    let feedCellID = "FeedCell"

    var feeds = [DiscoveredFeed]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.feedsCollectionView.reloadData()
            }
        }
    }

    private func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedCell.messageLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

        let height: CGFloat
        if feed.attachments.isEmpty {
            height = ceil(rect.height) + 10 + 40 + 4 + 10 + 20.5 + 10
        } else {
            height = ceil(rect.height) + 10 + 40 + 4 + 10 + 80 + 10 + 20.5 + 10
        }

        return ceil(height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feeds", comment: "")

        feedsCollectionView.backgroundColor = UIColor.whiteColor()
        feedsCollectionView.registerNib(UINib(nibName: feedCellID, bundle: nil), forCellWithReuseIdentifier: feedCellID)

        discoverFeedsWithSortStyle(.Time, pageIndex: 1, perPage: 100, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason, errorMessage: errorMessage)
        }, completion: { data in
            println("discoverFeeds \(data)")
        })

        myFeedsAtPageIndex(1, perPage: 100, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason, errorMessage: errorMessage)
        }, completion: { [weak self] feeds in
            self?.feeds = feeds
            println("myFeeds.count \(feeds.count)")
        })
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showConversation" {

            let vc = segue.destinationViewController as! ConversationViewController
            let realm = try! Realm()
            vc.conversation = realm.objects(Conversation).sorted("updatedUnixTime", ascending: false).first

            if let
                index = sender as? Int,
                feed = feeds[safe: index] {
                    vc.feed = feed
            }
        }
    }
}

extension FeedsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feeds.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedCellID, forIndexPath: indexPath) as! FeedCell

        let feed = feeds[indexPath.item]

        cell.configureWithFeed(feed)

        //cell.backgroundColor = indexPath.item % 2 == 0 ? UIColor.yellowColor() : UIColor.purpleColor()

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        let feed = feeds[indexPath.item]

        return CGSize(width: collectionViewWidth, height: heightOfFeed(feed))
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        performSegueWithIdentifier("showConversation", sender: indexPath.item)
    }

    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedCell
        cell.contentView.backgroundColor = UIColor.lightGrayColor()
    }

    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedCell
        cell.contentView.backgroundColor = UIColor.clearColor()
    }
}

